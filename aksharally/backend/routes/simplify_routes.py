from flask import Blueprint, request, jsonify
from modules.simplifier import process_text

simplify_bp = Blueprint("simplify", __name__)


@simplify_bp.route("/process/text-format", methods=["POST"])
def process_simplify():
    data = request.get_json()

    if not data or "text" not in data:
        return jsonify({
            "success": False,
            "error": "No text provided"
        }), 400

    original_text = data["text"]

    # 🔹 Language support (default = English)
    language = data.get("language", "en")

    formatted_text = process_text(original_text, language)

    return jsonify({
        "success": True,
        "original_text": original_text,
        "formatted_text": formatted_text
    })