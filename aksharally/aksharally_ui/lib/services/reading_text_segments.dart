/// Text tokenization and sentence boundaries shared by the reader and tests.
class ReadingTextSegments {
  static const String paragraphMarker = '¶';

  static List<String> splitToWords(String text) {
    final normalized = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final paragraphs = normalized
        .split(RegExp(r'\n\s*\n+'))
        .map((paragraph) => paragraph.trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .toList();
    final words = <String>[];

    for (var i = 0; i < paragraphs.length; i++) {
      words.addAll(
        paragraphs[i]
            .split(RegExp(r'\s+'))
            .where((word) => word.isNotEmpty),
      );
      if (i < paragraphs.length - 1) {
        words.add(paragraphMarker);
      }
    }
    return words;
  }

  static ReadingSentenceRange? sentenceAt(
    List<String> words,
    int wordIndex,
  ) {
    if (wordIndex < 0 || wordIndex >= words.length) return null;

    var activeIndex = wordIndex;
    while (activeIndex < words.length &&
        words[activeIndex] == paragraphMarker) {
      activeIndex++;
    }
    if (activeIndex >= words.length) return null;

    var first = activeIndex;
    while (first > 0) {
      final previous = words[first - 1];
      if (previous == paragraphMarker || endsSentence(previous)) break;
      first--;
    }

    var last = activeIndex;
    while (last < words.length - 1) {
      if (endsSentence(words[last]) ||
          words[last + 1] == paragraphMarker) {
        break;
      }
      last++;
    }

    return ReadingSentenceRange(firstWordIndex: first, lastWordIndex: last);
  }

  static bool endsSentence(String word) =>
      const ['.', '!', '?', '।', '॥', '…'].any(word.endsWith);

  /// Returns the original source text after [wordIndex], preserving spacing.
  ///
  /// Tokens are located in sequence so repeated words resolve to the correct
  /// occurrence instead of jumping back to an earlier match.
  static String textAfterWord(String text, List<String> words, int wordIndex) {
    var cursor = 0;
    for (var i = 0; i <= wordIndex && i < words.length; i++) {
      final token = words[i];
      if (token == paragraphMarker) continue;
      final position = text.indexOf(token, cursor);
      if (position < 0) continue;
      cursor = position + token.length;
    }
    return cursor <= text.length ? text.substring(cursor).trim() : '';
  }
}

class ReadingSentenceRange {
  const ReadingSentenceRange({
    required this.firstWordIndex,
    required this.lastWordIndex,
  });

  final int firstWordIndex;
  final int lastWordIndex;
}
