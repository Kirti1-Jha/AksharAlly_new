class FormatResult {
  final String processedText;
  final String profile;
  final double fontSize;
  final double lineHeight;
  final double letterSpacing;
  final double wordSpacing;
  final double paragraphSpacing;
  final String recommendedFont;
  final String sourceType;

  /// Raw extracted text before dyslexia formatting.
  /// Nullable: older backend responses or edge cases may not include it.
  /// Use [rawText] to access with a safe fallback.
  final String? originalText;

  /// Returns the raw OCR/extracted text if available, otherwise falls back
  /// to [processedText].  Use this as the input to Gemini simplification
  /// so the pipeline is OCR → Simplify → Format rather than
  /// OCR → Format → Simplify.
  String get rawText => originalText ?? processedText;

  const FormatResult({
    required this.processedText,
    required this.profile,
    required this.fontSize,
    required this.lineHeight,
    required this.letterSpacing,
    required this.wordSpacing,
    required this.paragraphSpacing,
    required this.recommendedFont,
    this.sourceType = 'unknown',
    this.originalText,
  });

  factory FormatResult.fromJson(Map<String, dynamic> json) {
    return FormatResult(
      processedText:    json['processedText']    as String,
      profile:          json['profile']          as String,
      fontSize:         (json['fontSize']        as num).toDouble(),
      lineHeight:       (json['lineHeight']      as num).toDouble(),
      letterSpacing:    (json['letterSpacing']   as num).toDouble(),
      wordSpacing:      (json['wordSpacing']     as num).toDouble(),
      paragraphSpacing: (json['paragraphSpacing'] as num).toDouble(),
      recommendedFont:  json['recommendedFont']  as String,
      sourceType:       json['sourceType']       as String? ?? 'unknown',
      originalText:     json['originalText']     as String?,
    );
  }
}
