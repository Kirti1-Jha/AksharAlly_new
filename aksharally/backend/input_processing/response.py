"""
Response helpers — every processor returns the exact same shape so callers
never need to check for different dict structures.
"""


def build_response(source_type: str, extracted_text: str) -> dict:
    """Build a successful standard response."""
    return {
        "status": "success",
        "sourceType": source_type,
        "extractedText": extracted_text,
        "characterCount": len(extracted_text),
        "wordCount": len(extracted_text.split()),
    }


def build_error(source_type: str, message: str) -> dict:
    """Build a failed standard response."""
    return {
        "status": "error",
        "sourceType": source_type,
        "extractedText": "",
        "characterCount": 0,
        "wordCount": 0,
        "error": message,
    }
