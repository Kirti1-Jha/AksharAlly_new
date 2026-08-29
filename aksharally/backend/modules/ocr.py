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


def _layout_text_from_tesseract(image, language):
    """Return OCR words grouped into their detected visual lines."""
    data = pytesseract.image_to_data(
        image,
        lang=_tesseract_language(language),
        config="--oem 3 --psm 3",
        output_type=pytesseract.Output.DICT,
    )

    lines = []
    current_key = None
    current_words = []

    for index, value in enumerate(data.get("text", [])):
        text = value.strip()
        if not text:
            continue

        key = (
            data["block_num"][index],
            data["par_num"][index],
            data["line_num"][index],
        )
        if current_key is not None and key != current_key:
            if current_words:
                lines.append(current_words)
            current_words = []
        current_key = key
        current_words.append((
            int(data["left"][index]),
            int(data["top"][index]),
            int(data["width"][index]),
            text,
        ))

    if current_words:
        lines.append(current_words)

    rendered = []
    for words in lines:
        words.sort(key=lambda item: item[0])
        pieces = []
        previous_right = None
        for left, _top, width, text in words:
            # Keep larger horizontal gaps visible so columns and label/value
            # relationships remain understandable in the returned text.
            if previous_right is not None:
                gap = left - previous_right
                separator = "  " if gap >= max(18, width * 0.7) else " "
                pieces.append(separator)
            pieces.append(text)
            previous_right = left + width
        rendered.append("".join(pieces))

    return "\n".join(rendered).strip()


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
