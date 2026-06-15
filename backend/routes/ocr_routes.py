from flask import Blueprint, request, jsonify
from modules.ocr import extract_text

# Create Blueprint for OCR routes
ocr_bp = Blueprint("ocr", __name__)


@ocr_bp.route("/process/ocr", methods=["POST"])
def process_ocr():
    """
    API endpoint to process OCR from uploaded image.
    """

    # Validate image input
    if "image" not in request.files:
        return jsonify({
            "success": False,
            "error": "No image file provided"
        }), 400

    image = request.files["image"]

    # Language support (default = English)
    language = request.form.get("language", "en")

    # Validate file type
    if not image.filename.lower().endswith((".png", ".jpg", ".jpeg")):
        return jsonify({
            "success": False,
            "error": "Invalid file type. Only PNG, JPG, JPEG allowed."
        }), 400

    # Extract text using OCR module (with error handling)
    try:
        # Pass language to OCR
        extracted_text = extract_text(image, language)
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

    # Return response
    return jsonify({
        "success": True,
        "extracted_text": extracted_text
    })