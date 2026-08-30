"""
OCR Service — wraps the existing modules/ocr.py so the input_processing
package has a single, clean interface to text extraction from images.
"""

import numpy as np
from PIL import Image
import io

from modules.ocr import extract_document as _extract_document


def extract_text_from_bytes(image_bytes: bytes, language: str = "en") -> str:
    """
    Accept raw image bytes, convert to a numpy array and delegate to the
    existing OCR module (EasyOCR with pytesseract fallback).
    """
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    image_np = np.array(image)
    return _extract_document(image_np, language)["text"]


def extract_document_from_bytes(image_bytes: bytes, language: str = "en") -> dict:
    """Return OCR text plus the internal, structure-aware display model."""
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    return _extract_document(np.array(image), language)


def extract_text_from_pil(pil_image: Image.Image, language: str = "en") -> str:
    """
    Accept a PIL Image directly (used by the PDF processor when rendering
    a page to an image for OCR fallback).
    """
    image_np = np.array(pil_image.convert("RGB"))
    return _extract_document(image_np, language)["text"]
