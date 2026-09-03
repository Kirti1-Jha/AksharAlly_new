"""
OCR Service — wraps the existing modules/ocr.py so the input_processing
package has a single, clean interface to text extraction from images.
"""

import io
import subprocess

import numpy as np
from PIL import Image, ImageOps, UnidentifiedImageError

from modules.ocr import extract_text as _extract_text


def _decode_image(image_bytes: bytes) -> np.ndarray:
    """Decode uploaded image bytes and normalize EXIF orientation.

    Pillow handles JPG/PNG/WEBP directly. ImageMagick is used as a fallback
    for HEIC/HEIF files commonly returned by phone galleries. Both branches
    produce the same RGB numpy input for the existing OCR implementation.
    """
    try:
        with Image.open(io.BytesIO(image_bytes)) as pil_image:
            oriented = ImageOps.exif_transpose(pil_image)
            return np.array(oriented.convert("RGB"))
    except (UnidentifiedImageError, OSError, ValueError):
        try:
            converted = subprocess.run(
                ["magick", "-", "png:-"],
                input=image_bytes,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=True,
                timeout=10,
            )
            with Image.open(io.BytesIO(converted.stdout)) as converted_image:
                oriented = ImageOps.exif_transpose(converted_image)
                return np.array(oriented.convert("RGB"))
        except (FileNotFoundError, subprocess.SubprocessError,
                UnidentifiedImageError, OSError, ValueError) as exc:
            raise ValueError(
                "The image could not be decoded. Please choose a JPG, PNG, "
                "WEBP, HEIC, or HEIF image."
            ) from exc


def extract_text_from_bytes(image_bytes: bytes, language: str = "en") -> str:
    """
    Accept raw image bytes, convert to a numpy array and delegate to the
    existing OCR module (EasyOCR with pytesseract fallback).
    """
    image_np = _decode_image(image_bytes)
    return _extract_text(image_np, language)


def extract_text_from_pil(pil_image: Image.Image, language: str = "en") -> str:
    """
    Accept a PIL Image directly (used by the PDF processor when rendering
    a page to an image for OCR fallback).
    """
    image_np = np.array(pil_image.convert("RGB"))
    return _extract_text(image_np, language)
