"""
Gemini-first OCR for AksharAlly.

- Uses Gemini vision to transcribe ordinary image pages, including handwriting.
- Uses Tesseract for table/grid pages because spatial cell positions matter there.
- Falls back to Tesseract if Gemini is not configured or the API call fails.
- Preserves the public extract_document()/extract_text() interfaces.
"""

import io
import os
import re
from functools import lru_cache

import cv2
import numpy as np
import pytesseract
from PIL import Image
from dotenv import load_dotenv
from google import genai
from google.genai import types

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_OCR_MODEL = os.getenv("GEMINI_OCR_MODEL", "gemini-2.5-flash")

if GEMINI_API_KEY:
    _gemini_client = genai.Client(api_key=GEMINI_API_KEY)
    print(f"✅ Gemini OCR configured ({GEMINI_OCR_MODEL})")
else:
    _gemini_client = None
    print("⚠️ GEMINI_API_KEY not set; OCR will use Tesseract fallback")


def preprocess_image(image_np):
    """Prepare a grayscale image for Tesseract fallback."""
    if len(image_np.shape) == 3:
        gray = cv2.cvtColor(image_np, cv2.COLOR_RGB2GRAY)
    else:
        gray = image_np.copy()

    height, width = gray.shape
    if height < 1000 or width < 1000:
        gray = cv2.resize(
            gray, None, fx=1.5, fy=1.5, interpolation=cv2.INTER_CUBIC
        )

    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(gray)
    denoised = cv2.fastNlMeansDenoising(enhanced, h=10)
    return cv2.adaptiveThreshold(
        denoised,
        255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        11,
        2,
    )


def _tesseract_language(language):
    language = (language or "en").lower()
    if language == "hi":
        return "hin+eng"
    if language == "mr":
        return "mar+eng"
    return "eng"


def _tesseract_detections(image, language, psm=3):
    """Return Tesseract words with positions so the structure analyzer can run."""
    data = pytesseract.image_to_data(
        image,
        lang=_tesseract_language(language),
        config=f"--oem 3 --psm {psm}",
        output_type=pytesseract.Output.DICT,
    )
    detections = []
    for index, value in enumerate(data.get("text", [])):
        text = value.strip()
        if not text:
            continue
        try:
            confidence = float(data["conf"][index])
        except (ValueError, TypeError):
            confidence = -1.0
        detections.append({
            "text": text,
            "left": int(data["left"][index]),
            "top": int(data["top"][index]),
            "width": int(data["width"][index]),
            "height": int(data["height"][index]),
            "confidence": confidence,
            "lineKey": (
                int(data["block_num"][index]),
                int(data["par_num"][index]),
                int(data["line_num"][index]),
            ),
            "order": index,
        })
    return detections


def _render_detections(detections):
    """Render positioned OCR words into lines while retaining rough column gaps."""
    grouped = []
    by_key = {}
    for detection in detections:
        key = detection.get("lineKey", detection.get("order", 0))
        if key not in by_key:
            by_key[key] = []
            grouped.append(by_key[key])
        by_key[key].append(detection)

    rendered = []
    for words in grouped:
        words.sort(key=lambda item: item["left"])
        pieces = []
        previous_right = None
        for word in words:
            if previous_right is not None:
                gap = word["left"] - previous_right
                pieces.append("  " if gap >= max(18, word["width"] * 0.7) else " ")
            pieces.append(word["text"])
            previous_right = word["left"] + word["width"]
        rendered.append("".join(pieces))
    return "\n".join(rendered).strip()


def _group_line_positions(mask, axis, threshold_ratio=0.35):
    projection = mask.sum(axis=axis)
    limit = (mask.shape[axis] * 255) * threshold_ratio
    occupied = projection > limit
    groups = []
    start = None
    for index, present in enumerate(occupied):
        if present and start is None:
            start = index
        if (not present or index == len(occupied) - 1) and start is not None:
            end = index if present and index == len(occupied) - 1 else index - 1
            groups.append((start + end) // 2)
            start = None
    return groups


def _detect_table_grid(gray):
    """Detect a ruled table so cell extraction can use positional Tesseract OCR."""
    binary = cv2.threshold(gray, 200, 255, cv2.THRESH_BINARY_INV)[1]
    horizontal_kernel = cv2.getStructuringElement(
        cv2.MORPH_RECT, (max(20, gray.shape[1] // 25), 1)
    )
    vertical_kernel = cv2.getStructuringElement(
        cv2.MORPH_RECT, (1, max(20, gray.shape[0] // 15))
    )
    horizontal = cv2.morphologyEx(binary, cv2.MORPH_OPEN, horizontal_kernel)
    vertical = cv2.morphologyEx(binary, cv2.MORPH_OPEN, vertical_kernel)
    x_lines = _group_line_positions(vertical, axis=0)
    y_lines = _group_line_positions(horizontal, axis=1)
    if len(x_lines) < 3 or len(y_lines) < 3:
        return None

    intersections = 0
    for x_line in x_lines:
        for y_line in y_lines:
            ys = slice(max(0, y_line - 1), min(gray.shape[0], y_line + 2))
            xs = slice(max(0, x_line - 1), min(gray.shape[1], x_line + 2))
            if vertical[ys, xs].any() and horizontal[ys, xs].any():
                intersections += 1

    if intersections < max(4, len(x_lines) * len(y_lines) * 0.5):
        return None
    return {
        "xLines": x_lines,
        "yLines": y_lines,
        "horizontalMask": horizontal,
        "verticalMask": vertical,
    }


def _remove_table_lines(gray, grid):
    rules = cv2.bitwise_or(grid["horizontalMask"], grid["verticalMask"])
    return cv2.inpaint(gray, rules, 3, cv2.INPAINT_TELEA)


def _image_to_png_bytes(image_np):
    image = Image.fromarray(image_np.astype(np.uint8)).convert("RGB")
    buffer = io.BytesIO()
    image.save(buffer, format="PNG")
    return buffer.getvalue()


def _gemini_transcribe(image_np, language="en"):
    """Transcribe the supplied page image using Gemini vision."""
    if _gemini_client is None:
        raise RuntimeError("Gemini OCR is not configured: GEMINI_API_KEY is missing.")

    language = (language or "en").lower()
    language_name = {"en": "English", "hi": "Hindi", "mr": "Marathi"}.get(
        language, "the language visible in the image"
    )
    prompt = f"""
You are an OCR transcription engine for student notes.
Transcribe the visible text in this image in {language_name} (preserve other
languages/scripts if they appear). This is transcription, not summarization.

Rules:
- Preserve the author's wording, spelling where readable, line order, headings,
  numbering, bullets, symbols, equations, and paragraph breaks.
- Do not explain, summarize, translate, or add facts.
- Do not silently complete sentences or guess words from general knowledge.
- If a short span cannot be read, write [unclear] for that span.
- Keep mathematical expressions and abbreviations as close to the image as possible.
- Return only the transcription, with no preface or markdown code fences.
"""
    image_bytes = _image_to_png_bytes(image_np)
    response = _gemini_client.models.generate_content(
        model=GEMINI_OCR_MODEL,
        contents=[
            prompt,
            types.Part.from_bytes(data=image_bytes, mime_type="image/png"),
        ],
        config=types.GenerateContentConfig(
            temperature=0,
            max_output_tokens=8192,
        ),
    )
    text = (response.text or "").strip()
    text = re.sub(r"^\s*```(?:text|markdown)?\s*", "", text, flags=re.IGNORECASE)
    text = re.sub(r"\s*```\s*$", "", text)
    if not text:
        raise RuntimeError("Gemini returned an empty transcription.")
    return text


def _detections_from_transcribed_lines(text, image_shape):
    """
    Build approximate line-level boxes for the existing structure analyzer.
    Gemini returns the transcription rather than character bounding boxes.
    """
    height, width = image_shape[:2]
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    if not lines:
        return []

    line_height = max(1, int(height / max(len(lines) + 1, 2)))
    detections = []
    for index, line in enumerate(lines):
        top = min(max(0, index * line_height), max(0, height - line_height))
        detections.append({
            "text": line,
            "left": int(width * 0.03),
            "top": top,
            "width": int(width * 0.94),
            "height": line_height,
            "confidence": 0.0,  # Gemini does not provide calibrated OCR confidence.
            "lineKey": index,
            "order": index,
        })
    return detections


def extract_document(image_input, language="en"):
    """
    Return {'text', 'detections', 'structure'} for an image or RGB ndarray.

    Gemini handles normal full-page transcription, including handwritten notes.
    Tesseract is retained for grid/table pages and as a robust API/configuration
    fallback. The function signature remains compatible with existing callers.
    """
    if isinstance(image_input, np.ndarray):
        image_np = image_input
    else:
        image = Image.open(image_input).convert("RGB")
        image_np = np.array(image)

    if image_np.ndim == 2:
        image_np = cv2.cvtColor(image_np, cv2.COLOR_GRAY2RGB)
    elif image_np.shape[2] == 4:
        image_np = cv2.cvtColor(image_np, cv2.COLOR_RGBA2RGB)

    gray = cv2.cvtColor(image_np, cv2.COLOR_RGB2GRAY)
    grid = _detect_table_grid(gray)

    if grid:
        # Cell geometry matters more than semantic transcription for tables.
        ocr_image = _remove_table_lines(gray, grid)
        detections = _tesseract_detections(ocr_image, language, psm=6)
        rendered_text = _render_detections(detections)
        if not rendered_text:
            detections = _tesseract_detections(preprocess_image(image_np), language)
            rendered_text = _render_detections(detections)
    else:
        try:
            rendered_text = _gemini_transcribe(image_np, language)
            detections = _detections_from_transcribed_lines(rendered_text, image_np.shape)
            print("✅ Image transcription completed with Gemini")
        except Exception as error:
            print(f"⚠️ Gemini OCR failed; using Tesseract fallback: {error}")
            detections = _tesseract_detections(gray, language, psm=3)
            rendered_text = _render_detections(detections)
            if not rendered_text:
                detections = _tesseract_detections(preprocess_image(image_np), language)
                rendered_text = _render_detections(detections)

    from input_processing.structure_analyzer import analyze_structure
    structure = analyze_structure(
        image_np.shape,
        detections,
        {"xLines": grid["xLines"], "yLines": grid["yLines"]} if grid else None,
        rendered_text,
    )
    return {
        "text": rendered_text,
        "detections": detections,
        "structure": structure,
    }


def extract_text(image_input, language="en"):
    """Backward-compatible text-only wrapper."""
    return extract_document(image_input, language)["text"]
