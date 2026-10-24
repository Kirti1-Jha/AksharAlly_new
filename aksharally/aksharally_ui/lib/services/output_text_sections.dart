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
        // Prefer paragraph breaks close to the limit before considering
        // sentence boundaries.
        var foundParagraphBoundary = false;
        final earliestPreferredBreak = tokenStart + (wordLimit ~/ 2);
        for (
          var candidate = hardEnd;
          candidate >= earliestPreferredBreak && candidate > tokenStart;
          candidate--
        ) {
          if (_isParagraphBoundary(text, tokens, candidate)) {
            tokenEnd = candidate;
            foundParagraphBoundary = true;
            break;
          }
        }

        var foundSentenceBoundary = false;
        if (!foundParagraphBoundary) {
          // Otherwise, end at the nearest complete sentence before the limit.
          for (var candidate = hardEnd; candidate > tokenStart; candidate--) {
            if (_isSentenceBoundary(tokens, candidate)) {
              tokenEnd = candidate;
              foundSentenceBoundary = true;
              break;
            }
          }
        }

        if (!foundParagraphBoundary && !foundSentenceBoundary) {
          // No complete sentence fits. Keep the sentence crossing the limit
          // intact by extending through its first sentence or paragraph end.
          for (
            var candidate = hardEnd + 1;
            candidate <= tokens.length;
            candidate++
          ) {
            if (_isSentenceBoundary(tokens, candidate) ||
                _isParagraphBoundary(text, tokens, candidate)) {
              tokenEnd = candidate;
              foundSentenceBoundary = true;
              break;
            }
          }
          if (!foundSentenceBoundary) tokenEnd = tokens.length;
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

  static bool _isSentenceBoundary(List<RegExpMatch> tokens, int boundary) =>
      boundary > 0 &&
      _isSentenceEnding(tokens[boundary - 1].group(0)!);

  static bool _isSentenceEnding(String token) {
    var end = token.length;
    const closingPunctuation = {'"', "'", '”', '’', ')', ']', '}', '»'};
    while (end > 0 &&
        closingPunctuation.contains(token.substring(end - 1, end))) {
      end--;
    }
    if (end == 0) return false;
    const sentencePunctuation = '.!?。！？।॥…';
    return sentencePunctuation.contains(token.substring(end - 1, end));
  }

  static bool _isParagraphBoundary(
    String text,
    List<RegExpMatch> tokens,
    int boundary,
  ) {
    if (boundary <= 0 || boundary >= tokens.length) return false;
    final gap = text.substring(
      tokens[boundary - 1].end,
      tokens[boundary].start,
    );
    return RegExp(r'(?:\r?\n)[ \t]*(?:\r?\n)').hasMatch(gap);
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
