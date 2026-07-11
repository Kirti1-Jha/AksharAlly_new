class LibraryItem {
  final String title;
  final String content;
  final DateTime date;
  final String sourceType;    // 'image' | 'pdf' | 'docx' | 'text' | 'simplified'

  LibraryItem({
    required this.title,
    required this.content,
    required this.date,
    this.sourceType = 'unknown',
  });
}
