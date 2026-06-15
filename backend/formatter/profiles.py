"""
Dyslexia Reading Profiles Configuration
----------------------------------------
Defines typography settings for three severity levels.

All values are Flutter-compatible:
  - lineHeight      : float multiplier (Flutter TextStyle.height)
  - letterSpacing   : logical pixels (Flutter TextStyle.letterSpacing)
  - wordSpacing     : logical pixels (Flutter TextStyle.wordSpacing)
  - fontSize        : logical pixels (Flutter TextStyle.fontSize)
  - paragraphSpacing: logical pixels — vertical gap between text blocks
  - recommendedFont : font-family name available via the google_fonts package
"""

PROFILES = {
    "mild": {
        "fontSize": 18.0,
        "lineHeight": 1.6,
        "letterSpacing": 0.5,
        "wordSpacing": 2.0,
        "paragraphSpacing": 12.0,
        "recommendedFont": "Lexend",
    },
    "moderate": {
        "fontSize": 20.0,
        "lineHeight": 1.8,
        "letterSpacing": 1.0,
        "wordSpacing": 4.0,
        "paragraphSpacing": 16.0,
        "recommendedFont": "Lexend",
    },
    "severe": {
        "fontSize": 22.0,
        "lineHeight": 2.0,
        "letterSpacing": 1.5,
        "wordSpacing": 6.0,
        "paragraphSpacing": 20.0,
        "recommendedFont": "Lexend",
    },
}

DEFAULT_PROFILE = "moderate"


def get_profile(name: str) -> tuple[str, dict]:
    """
    Retrieve a reading profile by name.

    Args:
        name: One of "mild", "moderate", or "severe".
              Falls back to DEFAULT_PROFILE when unrecognised.

    Returns:
        A tuple of (resolved_profile_name, profile_settings_dict).
    """
    resolved = name.lower() if name and name.lower() in PROFILES else DEFAULT_PROFILE
    return resolved, PROFILES[resolved]
