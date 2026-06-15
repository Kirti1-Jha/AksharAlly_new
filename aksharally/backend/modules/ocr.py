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
        gray = cv2.cvtColor(image_np, cv2.COLOR_BGR2GRAY)
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


def extract_text(image_input, language="en"):
    if isinstance(image_input, np.ndarray):
        image_np = image_input
    else:
        image = Image.open(image_input).convert("RGB")
        image_np = np.array(image)

    processed = preprocess_image(image_np)

    if EASYOCR_AVAILABLE:
        results = reader.readtext(
            processed,
            detail=0,
            paragraph=True
        )
        return " ".join(results).strip()
    else:
        lang_code = "hin+eng" if language == "hi" else "eng"
        text = pytesseract.image_to_string(processed, lang=lang_code)
        return text.strip()
