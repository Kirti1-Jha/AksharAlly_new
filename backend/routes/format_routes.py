"""
Dyslexia-Friendly Text Formatter — Route Layer
------------------------------------------------
Defines the REST API endpoint for the formatter feature.
Keeps HTTP-level concerns (request parsing, response serialisation)
separate from business logic, which lives in the controller and service.

Endpoint:
  POST /api/format-text
"""

from flask import Blueprint, request, jsonify
from formatter.controller import handle_format_text

# Blueprint groups all formatter-related routes under a single prefix.
# url_prefix="/api" means the full path becomes /api/format-text.
format_bp = Blueprint("format", __name__, url_prefix="/api")


@format_bp.route("/format-text", methods=["POST"])
def format_text_endpoint():
    """
    POST /api/format-text

    Accepts a JSON body with the text to format and an optional reading profile.

    Request body:
      {
        "text": "Long paragraph to reformat...",
        "profile": "moderate",          // optional: mild | moderate | severe
        "sentencesPerChunk": 2,         // optional: sentences per visual block
        "maxLineLength": 60             // optional: character wrap limit
      }

    Response (200):
      {
        "processedText": "...",
        "profile": "moderate",
        "lineHeight": "1.8",
        "letterSpacing": "0.1em",
        "wordSpacing": "0.2em"
      }

    Error response (400 / 500):
      {
        "success": false,
        "error": "..."
      }
    """

    # Parse JSON body; returns None if Content-Type is not application/json
    data = request.get_json(silent=True)

    # Delegate all validation and processing to the controller
    response_body, status_code = handle_format_text(data)

    return jsonify(response_body), status_code
