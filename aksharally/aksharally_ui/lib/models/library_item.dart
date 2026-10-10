class LibraryItem {
  final String title;
  final String content;
  final DateTime date;
  final String sourceType; // 'image' | 'pdf' | 'docx' | 'text' | 'simplified'

  LibraryItem({
    required this.title,
    required this.content,
    required this.date,
    this.sourceType = 'unknown',
  });

  // ── JSON serialisation ────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'title':      title,
        'content':    content,
        'date':       date.toIso8601String(),
        'sourceType': sourceType,
      };

  factory LibraryItem.fromJson(Map<String, dynamic> json) => LibraryItem(
        title:      json['title']      as String? ?? '',
        content:    json['content']    as String? ?? '',
        date:       DateTime.tryParse(json['date'] as String? ?? '') ??
                    DateTime.now(),
        sourceType: json['sourceType'] as String? ?? 'unknown',
      );
}
