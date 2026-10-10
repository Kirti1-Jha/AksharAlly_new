"""
PDF Processor — extracts text from PDFs.

Strategy:
  1. Try direct text extraction using PyMuPDF (fast, works for text-based PDFs).
  2. If no text is found (scanned/image-based PDF), render each page to a
     PIL Image and run OCR on it as a fallback.
"""

import fitz  # PyMuPDF
from PIL import Image
import io

from .ocr_service import extract_text_from_pil
from .response import build_response, build_error

MAX_SIZE_MB = 20
MIN_TEXT_CHARS = 30  # threshold below which we assume the page is image-based


def process_pdf(file_storage, language: str = "en") -> dict:
    """
    Accept a Werkzeug FileStorage object for a PDF file.
    Returns a unified response with all extracted text concatenated.
    """
    if file_storage is None or file_storage.filename == "":
        return build_error("pdf", "No PDF file provided.")

    filename = file_storage.filename.lower()
    if not filename.endswith(".pdf"):
        return build_error("pdf", "File does not have a .pdf extension.")

    pdf_bytes = file_storage.read()

    if not pdf_bytes:
        return build_error("pdf", "Uploaded PDF is empty.")

    size_mb = len(pdf_bytes) / (1024 * 1024)
    if size_mb > MAX_SIZE_MB:
        return build_error("pdf", f"File too large ({size_mb:.1f} MB). Max is {MAX_SIZE_MB} MB.")

    try:
        doc = fitz.open(stream=pdf_bytes, filetype="pdf")
    except Exception as e:
        return build_error("pdf", f"Could not open PDF: {str(e)}")

    if doc.page_count == 0:
        return build_error("pdf", "PDF contains no pages.")

    all_text_parts = []

    for page_num in range(doc.page_count):
        page = doc[page_num]

        # Attempt direct text extraction first
        page_text = page.get_text().strip()

        if len(page_text) >= MIN_TEXT_CHARS:
            all_text_parts.append(page_text)
        else:
            # Fall back to OCR: render page to image
            try:
                pix = page.get_pixmap(dpi=200)
                img_bytes = pix.tobytes("png")
                pil_img = Image.open(io.BytesIO(img_bytes))
                ocr_text = extract_text_from_pil(pil_img, language)
                if ocr_text:
                    all_text_parts.append(ocr_text)
            except Exception as e:
                # Log but continue with remaining pages
                print(f"⚠️ OCR fallback failed for page {page_num + 1}: {e}")

    doc.close()

    combined = "\n\n".join(all_text_parts).strip()

    if not combined:
        return build_error("pdf", "No text could be extracted from the PDF.")

    return build_response("pdf", combined)
