/// Splits long output into contiguous, word-bounded sections for the reader.
///
/// Section text is sliced from the original string, so punctuation, line
/// breaks, spacing, and paragraph order are retained exactly.
class OutputTextSections {
  static const int defaultMaxWordsPerSection = 180;

  static List<OutputTextSection> paginate({
    required String text,
    required List<int> spokenWordIndices,
    int maxWordsPerSection = defaultMaxWordsPerSection,
    int? displayWordCount,
  }) {
    final wordLimit = maxWordsPerSection < 1 ? 1 : maxWordsPerSection;
    final endOfDisplayWords =
        displayWordCount ??
        (spokenWordIndices.isEmpty ? 0 : spokenWordIndices.last + 1);
    if (text.isEmpty || spokenWordIndices.isEmpty) {
      return [
        OutputTextSection(
          text: text,
          startWordIndex: 0,
          endWordIndex: endOfDisplayWords,
        ),
      ];
    }

    final tokens = RegExp(r'\S+').allMatches(text).toList();
    if (tokens.length <= wordLimit ||
        tokens.length != spokenWordIndices.length) {
      return [
        OutputTextSection(
          text: text,
          startWordIndex: 0,
          endWordIndex: endOfDisplayWords,
        ),
      ];
    }

    final sections = <OutputTextSection>[];
    var tokenStart = 0;
    while (tokenStart < tokens.length) {
      final hardEnd = (tokenStart + wordLimit)
          .clamp(tokenStart + 1, tokens.length)
          .toInt();
      var tokenEnd = hardEnd;

      if (hardEnd < tokens.length) {
        // Prefer a paragraph boundary near the word limit, but never make a
        // section smaller than half the configured limit just to find one.
        final earliestPreferredBreak =
            tokenStart + (wordLimit ~/ 2);
        for (
          var candidate = hardEnd;
          candidate > earliestPreferredBreak;
          candidate--
        ) {
          final gap = text.substring(
            tokens[candidate - 1].end,
            tokens[candidate].start,
          );
          if (RegExp(r'(?:\r?\n)[ \t]*(?:\r?\n)').hasMatch(gap)) {
            tokenEnd = candidate;
            break;
          }
        }
      }

      final startOffset = tokenStart == 0 ? 0 : tokens[tokenStart].start;
      final endOffset = tokenEnd == tokens.length
          ? text.length
          : tokens[tokenEnd].start;
      final startWordIndex = spokenWordIndices[tokenStart];
      final endWordIndex = tokenEnd == tokens.length
          ? endOfDisplayWords
          : spokenWordIndices[tokenEnd];

      sections.add(
        OutputTextSection(
          text: text.substring(startOffset, endOffset),
          startWordIndex: startWordIndex,
          endWordIndex: endWordIndex,
        ),
      );
      tokenStart = tokenEnd;
    }

    return sections;
  }
}

class OutputTextSection {
  const OutputTextSection({
    required this.text,
    required this.startWordIndex,
    required this.endWordIndex,
  });

  final String text;
  final int startWordIndex;
  final int endWordIndex;
}
