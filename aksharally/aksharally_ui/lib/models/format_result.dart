class FormatResult {
  final String processedText;
  final String profile;
  final double fontSize;
  final double lineHeight;
  final double letterSpacing;
  final double wordSpacing;
  final double paragraphSpacing;
  final String recommendedFont;
  final String sourceType;     // 'image' | 'pdf' | 'docx' | 'text'

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
  });

  factory FormatResult.fromJson(Map<String, dynamic> json) {
    return FormatResult(
      processedText:    json['processedText']    as String,
      profile:          json['profile']          as String,
      fontSize:         (json['fontSize']        as num).toDouble(),
      lineHeight:       (json['lineHeight']       as num).toDouble(),
      letterSpacing:    (json['letterSpacing']    as num).toDouble(),
      wordSpacing:      (json['wordSpacing']      as num).toDouble(),
      paragraphSpacing: (json['paragraphSpacing'] as num).toDouble(),
      recommendedFont:  json['recommendedFont']   as String,
      sourceType:       json['sourceType']        as String? ?? 'unknown',
    );
  }
}
