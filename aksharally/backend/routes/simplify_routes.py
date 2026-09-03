from flask import Blueprint, request, jsonify
from modules.simplifier import process_text

simplify_bp = Blueprint("simplify", __name__)


@simplify_bp.route("/process/text-format", methods=["POST"])
def process_simplify():
    """
    Simplify text for dyslexia-friendly reading using Google Gemini AI.
    ---
    tags:
      - Simplification
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
              description: The text to simplify
              example: The mitochondria is the powerhouse of the cell and produces ATP through cellular respiration.
            language:
              type: string
              enum: [en, hi, mr]
              default: en
              description: Language of the text
    responses:
      200:
        description: Text simplified successfully
        schema:
          type: object
          properties:
            success:
              type: boolean
              example: true
            original_text:
              type: string
              example: The mitochondria is the powerhouse of the cell.
            formatted_text:
              type: string
              example: Mitochondria makes energy. It powers the cell.
      400:
        description: No text provided
        schema:
          type: object
          properties:
            success:
              type: boolean
              example: false
            error:
              type: string
              example: No text provided
    """
    data = request.get_json()

    if not data or "text" not in data:
        return jsonify({"success": False, "error": "No text provided"}), 400

    original_text = data["text"]
    language = data.get("language", "en")
    formatted_text = process_text(original_text, language)

    return jsonify({
        "success": True,
        "original_text": original_text,
        "formatted_text": formatted_text
    })
