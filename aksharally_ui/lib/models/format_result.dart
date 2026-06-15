/// Model for the response returned by POST /api/format-text.
///
/// All typography fields map directly to Flutter TextStyle parameters:
///   - [fontSize]         → TextStyle.fontSize
///   - [lineHeight]       → TextStyle.height  (multiplier, e.g. 1.8)
///   - [letterSpacing]    → TextStyle.letterSpacing  (logical pixels)
///   - [wordSpacing]      → TextStyle.wordSpacing    (logical pixels)
///   - [paragraphSpacing] → SizedBox height between paragraph chunks
///   - [recommendedFont]  → font family name for google_fonts lookup
///   - [profile]          → which severity tier was applied
class FormatResult {
  final String processedText;
  final String profile;
  final double fontSize;
  final double lineHeight;
  final double letterSpacing;
  final double wordSpacing;
  final double paragraphSpacing;
  final String recommendedFont;

  const FormatResult({
    required this.processedText,
    required this.profile,
    required this.fontSize,
    required this.lineHeight,
    required this.letterSpacing,
    required this.wordSpacing,
    required this.paragraphSpacing,
    required this.recommendedFont,
  });

  /// Deserialise a successful /api/format-text response body.
  factory FormatResult.fromJson(Map<String, dynamic> json) {
    return FormatResult(
      processedText:    json['processedText']    as String,
      profile:          json['profile']          as String,
      fontSize:         (json['fontSize']         as num).toDouble(),
      lineHeight:       (json['lineHeight']       as num).toDouble(),
      letterSpacing:    (json['letterSpacing']    as num).toDouble(),
      wordSpacing:      (json['wordSpacing']      as num).toDouble(),
      paragraphSpacing: (json['paragraphSpacing'] as num).toDouble(),
      recommendedFont:  json['recommendedFont']   as String,
    );
  }

  /// Constructs a [FormatResult] from a known profile name without an API
  /// call, using values that mirror the backend formatter/profiles.py exactly.
  ///
  /// Used when reopening a library item so the correct typography is applied
  /// instantly — no network round-trip required.
  factory FormatResult.fromProfile(String text, String profile) {
    final Map<String, Map<String, double>> settings = {
      'mild': {
        'fontSize': 18.0, 'lineHeight': 1.6,
        'letterSpacing': 0.5, 'wordSpacing': 2.0, 'paragraphSpacing': 12.0,
      },
      'moderate': {
        'fontSize': 20.0, 'lineHeight': 1.8,
        'letterSpacing': 1.0, 'wordSpacing': 4.0, 'paragraphSpacing': 16.0,
      },
      'severe': {
        'fontSize': 22.0, 'lineHeight': 2.0,
        'letterSpacing': 1.5, 'wordSpacing': 6.0, 'paragraphSpacing': 20.0,
      },
    };
    final s = settings[profile] ?? settings['moderate']!;

    return FormatResult(
      processedText:    text,
      profile:          profile,
      fontSize:         s['fontSize']!,
      lineHeight:       s['lineHeight']!,
      letterSpacing:    s['letterSpacing']!,
      wordSpacing:      s['wordSpacing']!,
      paragraphSpacing: s['paragraphSpacing']!,
      recommendedFont:  'Lexend',
    );
  }

  /// Fallback result used when the format endpoint is unreachable,
  /// so the reader can still display the simplified text.
  factory FormatResult.fallback(String text, {String profile = 'moderate'}) {
    return FormatResult.fromProfile(text, profile);
  }
}
