"""
Simplify Text Routes — POST /api/simplify-text

Takes already-extracted text and simplifies it using Google Gemini AI.
This is a SEPARATE, OPTIONAL step that only runs when the user explicitly
requests simplification (e.g. by pressing a "Simplify Text" button).

This endpoint does NOT do OCR or document extraction.
"""

from flask import Blueprint, request, jsonify
from modules.simplifier import process_text as gemini_simplify

simplify_text_bp = Blueprint("simplify_text", __name__)


@simplify_text_bp.route("/api/simplify-text", methods=["POST"])
def simplify_text():
    """
    Simplify text using Gemini AI. Only call this when the user explicitly requests it.
    ---
    tags:
      - Dyslexia Formatter
    consumes:
      - application/json
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required:
            - text
          properties:
            text:
              type: string
              description: The extracted text to simplify
              example: The mitochondria is the powerhouse of the cell and produces ATP through cellular respiration.
            language:
              type: string
              enum: [en, hi, mr]
              default: en
              description: Language of the text (en, hi, or mr — Gemini will respond in the same language)
    responses:
      200:
        description: Text simplified successfully
        schema:
          type: object
          properties:
            status:
              type: string
              example: success
            language:
              type: string
              example: en
            originalText:
              type: string
              example: The mitochondria is the powerhouse of the cell.
            simplifiedText:
              type: string
              example: The mitochondria gives energy to the cell.
      400:
        description: Missing or empty text field
        schema:
          type: object
          properties:
            status:
              type: string
              example: error
            error:
              type: string
              example: 'Missing required field: text'
      503:
        description: Gemini API unavailable (missing API key)
    """
    data = request.get_json(silent=True) or {}

    text = data.get("text", "").strip()
    language = data.get("language", "en")

    if not text:
        return jsonify({
            "status": "error",
            "error": "Missing required field: text",
        }), 400

    if language not in ("en", "hi", "mr"):
        language = "en"

    try:
        simplified = gemini_simplify(text, language)
    except Exception as e:
        return jsonify({
            "status": "error",
            "error": f"Simplification failed: {str(e)}",
        }), 503

    return jsonify({
        "status":         "success",
        "language":       language,
        "originalText":   text,
        "simplifiedText": simplified,
    }), 200
