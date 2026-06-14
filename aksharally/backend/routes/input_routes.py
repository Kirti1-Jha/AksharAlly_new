"""
Input Routes — exposes the unified POST /api/process-input endpoint.

All input types (text, image, camera, PDF, DOCX) flow through this single
endpoint. The input_router decides which processor to call based on what
is in the request.
"""

from flask import Blueprint, request, jsonify
from input_processing.input_router import route_input

input_bp = Blueprint("input", __name__)


@input_bp.route("/api/process-input", methods=["POST"])
def process_input():
    """
    Unified input processing endpoint.

    Accepted inputs
    ---------------
    • Direct text  — form field 'text'  OR  JSON body {"text": "..."}
    • Image upload — multipart 'file' (.jpg / .jpeg / .png / .webp)
    • Camera image — multipart 'file' (same as image upload)
    • PDF          — multipart 'file' (.pdf)
    • DOCX         — multipart 'file' (.docx)

    Optional parameters
    -------------------
    • language     — 'en' (default) or 'hi' for Hindi OCR
                     Pass as a form field or query param: ?language=hi

    Response (always the same shape)
    ---------------------------------
    {
        "status": "success" | "error",
        "sourceType": "text" | "image" | "pdf" | "docx" | "unknown",
        "extractedText": "...",
        "characterCount": 0,
        "wordCount": 0,
        "error": "..."   // only present on error
    }
    """
    language = request.args.get("language") or request.form.get("language", "en")

    result = route_input(request, language)

    http_status = 200 if result.get("status") == "success" else 400
    return jsonify(result), http_status
