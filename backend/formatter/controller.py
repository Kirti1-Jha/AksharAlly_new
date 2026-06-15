"""
Dyslexia-Friendly Text Formatter — Controller Layer
-----------------------------------------------------
Acts as the bridge between the HTTP route and the service layer.

Responsibilities:
  - Validate and extract fields from the parsed request body.
  - Call the service and profile helpers.
  - Assemble the final JSON-ready response dict with Flutter-compatible values.
  - Return structured errors so the route layer can respond cleanly.
"""

from formatter.service import format_text
from formatter.profiles import get_profile


def handle_format_text(data: dict) -> tuple[dict, int]:
    """
    Validate the request payload, run the formatter, and build the response.

    Args:
        data: Parsed JSON body from the HTTP request.
              Expected keys:
                - "text"             (str, required) — plain text to format.
                - "profile"          (str, optional) — "mild" | "moderate" | "severe".
                - "sentencesPerChunk"(int, optional) — sentences per block.
                - "maxLineLength"    (int, optional) — character wrap limit.

    Returns:
        A tuple of (response_dict, http_status_code).
        On success the dict contains Flutter-ready typography fields:
          {
            "processedText":    str,
            "profile":          str,
            "fontSize":         float,
            "lineHeight":       float,
            "letterSpacing":    float,
            "wordSpacing":      float,
            "paragraphSpacing": float,
            "recommendedFont":  str
          }
        On failure: {"success": False, "error": str}
    """

    # ── Validate required field ──────────────────────────────────────────────
    if not data or "text" not in data:
        return {"success": False, "error": "Missing required field: 'text'"}, 400

    raw_text: str = data.get("text", "")

    if not isinstance(raw_text, str) or not raw_text.strip():
        return {"success": False, "error": "'text' must be a non-empty string"}, 400

    # ── Resolve reading profile ──────────────────────────────────────────────
    requested_profile: str = data.get("profile", "moderate")
    profile_name, profile_settings = get_profile(requested_profile)

    # ── Optional formatting parameters ──────────────────────────────────────
    sentences_per_chunk: int = int(data.get("sentencesPerChunk", 2))

    raw_max_line = data.get("maxLineLength")
    max_line_length: int | None = int(raw_max_line) if raw_max_line else None

    # ── Run the formatting service ───────────────────────────────────────────
    try:
        processed_text = format_text(
            text=raw_text,
            sentences_per_chunk=sentences_per_chunk,
            max_line_length=max_line_length,
        )
    except Exception as exc:
        return {"success": False, "error": f"Formatting failed: {str(exc)}"}, 500

    # ── Build Flutter-compatible response ────────────────────────────────────
    # All numeric values are bare floats — no CSS units — so Flutter can
    # pass them directly to TextStyle without any string parsing.
    response = {
        "processedText":    processed_text,
        "profile":          profile_name,
        "fontSize":         profile_settings["fontSize"],
        "lineHeight":       profile_settings["lineHeight"],
        "letterSpacing":    profile_settings["letterSpacing"],
        "wordSpacing":      profile_settings["wordSpacing"],
        "paragraphSpacing": profile_settings["paragraphSpacing"],
        "recommendedFont":  profile_settings["recommendedFont"],
    }

    return response, 200
