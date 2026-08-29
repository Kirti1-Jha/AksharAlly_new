import cv2
import numpy as np
from PIL import Image
import pytesseract

try:
    import easyocr
    reader = easyocr.Reader(['en', 'hi'], gpu=False)
    EASYOCR_AVAILABLE = True
    print("✅ EasyOCR loaded successfully")
except Exception as e:
    EASYOCR_AVAILABLE = False
    reader = None
    print(f"⚠️ EasyOCR not available ({e}), falling back to pytesseract")


def preprocess_image(image_np):
    if len(image_np.shape) == 3:
        # PIL supplies RGB arrays. Treating them as BGR subtly damages
        # colour-to-gray conversion before OCR.
        gray = cv2.cvtColor(image_np, cv2.COLOR_RGB2GRAY)
    else:
        gray = image_np

    height, width = gray.shape

    if height < 1000 or width < 1000:
        gray = cv2.resize(
            gray, None, fx=1.5, fy=1.5,
            interpolation=cv2.INTER_CUBIC
        )

    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(gray)

    denoised = cv2.fastNlMeansDenoising(enhanced, h=10)

    thresh = cv2.adaptiveThreshold(
        denoised,
        255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        11,
        2
    )

    return thresh


def _tesseract_language(language):
    language = (language or "en").lower()
    if language == "hi":
        return "hin+eng"
    if language == "mr":
        return "mar+eng"
    return "eng"


def _tesseract_detections(image, language, psm=3):
    """Return OCR words with their positions instead of flattening them."""
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
        detections.append({
            "text": text,
            "left": int(data["left"][index]),
            "top": int(data["top"][index]),
            "width": int(data["width"][index]),
            "height": int(data["height"][index]),
            "confidence": float(data["conf"][index]),
            "lineKey": (
                int(data["block_num"][index]),
                int(data["par_num"][index]),
                int(data["line_num"][index]),
            ),
            "order": index,
        })
    return detections


def _render_detections(detections):
    """Render positioned OCR words into lines while keeping column gaps."""
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


def _layout_text_from_tesseract(image, language):
    """Compatibility wrapper returning layout-preserving OCR text."""
    return _render_detections(_tesseract_detections(image, language))


def _group_line_positions(mask, axis, threshold_ratio=0.35):
    """Find contiguous x/y positions occupied by strong table lines."""
    projection = mask.sum(axis=axis)
    limit = (mask.shape[1 - axis] * 255) * threshold_ratio
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
    """Detect substantial horizontal and vertical table rules."""
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
    return {
        "xLines": x_lines,
        "yLines": y_lines,
        "horizontalMask": horizontal,
        "verticalMask": vertical,
    }


def _remove_table_lines(gray, grid):
    """Remove detected rules while leaving text pixels intact for OCR."""
    rules = cv2.bitwise_or(grid["horizontalMask"], grid["verticalMask"])
    return cv2.inpaint(gray, rules, 3, cv2.INPAINT_TELEA)


def _easyocr_detections(results):
    detections = []
    for order, result in enumerate(results):
        bounding_box, text, confidence = result
        text = text.strip()
        if not text:
            continue
        xs = [point[0] for point in bounding_box]
        ys = [point[1] for point in bounding_box]
        left, right = min(xs), max(xs)
        top, bottom = min(ys), max(ys)
        detections.append({
            "text": text,
            "left": int(left),
            "top": int(top),
            "width": int(right - left),
            "height": int(bottom - top),
            "confidence": float(confidence),
            "lineKey": order,
            "order": order,
        })
    return detections


def _layout_text_from_easyocr(results):
    """Group EasyOCR boxes into lines instead of flattening them."""
    words = []
    for bounding_box, text, _confidence in results:
        if not text.strip():
            continue
        xs = [point[0] for point in bounding_box]
        ys = [point[1] for point in bounding_box]
        words.append((
            min(xs),
            min(ys),
            max(xs),
            max(ys),
            text.strip(),
        ))

    words.sort(key=lambda item: (item[1], item[0]))
    lines = []
    for word in words:
        center_y = (word[1] + word[3]) / 2
        matching_line = None
        for line in lines:
            if abs(center_y - line["center_y"]) <= max(12, word[3] - word[1]):
                matching_line = line
                break
        if matching_line is None:
            matching_line = {"center_y": center_y, "words": []}
            lines.append(matching_line)
        matching_line["words"].append(word)

    rendered = []
    for line in lines:
        line["words"].sort(key=lambda item: item[0])
        rendered.append(" ".join(word[4] for word in line["words"]))
    return "\n".join(rendered).strip()


def extract_text(image_input, language="en"):
    if isinstance(image_input, np.ndarray):
        image_np = image_input
    else:
        image = Image.open(image_input).convert("RGB")
        image_np = np.array(image)

    if EASYOCR_AVAILABLE:
        # Use EasyOCR's box result shape so visual lines can be rebuilt.
        results = reader.readtext(image_np, detail=1, paragraph=False)
        return _layout_text_from_easyocr(results)

    # Run Tesseract on the original grayscale image first. It preserves
    # document lines and table rows better than adaptive thresholding.
    gray = cv2.cvtColor(image_np, cv2.COLOR_RGB2GRAY)
    text = _layout_text_from_tesseract(gray, language)
    if text:
        return text

    # Low-contrast captures get a second, conservative preprocessing pass.
    return _layout_text_from_tesseract(preprocess_image(image_np), language)
