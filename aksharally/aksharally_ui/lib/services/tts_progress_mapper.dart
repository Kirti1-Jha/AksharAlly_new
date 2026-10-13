/// Maps `flutter_tts` UTF-16 source offsets to indices in the displayed words.
///
/// Both FlutterTts and Dart String offsets use UTF-16 code units on the
/// supported native platforms. Matching by ranges, rather than matching the
/// callback's word text, keeps repeated words and punctuation unambiguous.
class TtsProgressMapper {
  TtsProgressMapper({
    required this.text,
    required List<int> displayWordIndices,
  }) : _spans = [] {
    final matches = RegExp(r'\S+').allMatches(text);
    var position = 0;
    for (final match in matches) {
      if (position >= displayWordIndices.length) break;
      _spans.add(
        _TtsWordSpan(
          start: match.start,
          end: match.end,
          displayIndex: displayWordIndices[position],
          text: match.group(0)!,
        ),
      );
      position++;
    }
  }

  final String text;
  final List<_TtsWordSpan> _spans;

  int get wordCount => _spans.length;

  String? wordAtPosition(int position) {
    if (position < 0 || position >= _spans.length) return null;
    return _spans[position].text;
  }

  int? displayIndexAtPosition(int position) {
    if (position < 0 || position >= _spans.length) return null;
    return _spans[position].displayIndex;
  }

  int? sourceOffsetAtPosition(int position) {
    if (position < 0 || position >= _spans.length) return null;
    return _spans[position].start;
  }

  int? positionForDisplayIndex(int displayIndex) {
    final position = _spans.indexWhere(
      (span) => span.displayIndex == displayIndex,
    );
    return position < 0 ? null : position;
  }

  /// Returns the displayed word touched by a progress range.
  ///
  /// Empty or out-of-range callbacks resolve to the nearest following word;
  /// callbacks beyond the spoken text stay on the last word.
  int? displayIndexForRange(int start, int end) {
    if (_spans.isEmpty) return null;
    final safeStart = start.clamp(0, text.length).toInt();
    final safeEnd = end.clamp(safeStart, text.length).toInt();

    if (safeEnd > safeStart) {
      for (final span in _spans) {
        if (span.start < safeEnd && span.end > safeStart) {
          return span.displayIndex;
        }
      }
    }

    for (final span in _spans) {
      if (safeStart >= span.start && safeStart < span.end) {
        return span.displayIndex;
      }
      if (span.start >= safeStart) return span.displayIndex;
    }
    return _spans.last.displayIndex;
  }

  /// Older Android speech engines may report the whole utterance as one range.
  bool isCoarseProgressWord(String word) =>
      _spans.length > 1 && RegExp(r'\s').hasMatch(word.trim());

  /// Approximate fallback timing for platforms without word-range events.
  ///
  /// This is intentionally an estimate, not a substitute for native progress
  /// callbacks. It scales with Unicode code-point count, punctuation, and the
  /// configured rate; accents, engine choice, and speaking style still cause
  /// drift.
  static Duration estimateWordDuration(String word, double speechRate) {
    final rate = speechRate.clamp(0.1, 1.0).toDouble();
    final codePoints = word.runes.length.clamp(1, 40).toInt();
    final punctuationPause = RegExp(r'[.!?。！？।॥…]+$').hasMatch(word)
        ? 360
        : RegExp(r'[,;:،؛]+$').hasMatch(word)
        ? 180
        : 0;
    final baseMilliseconds = 150 + (codePoints * 42) + punctuationPause;
    final estimatedMilliseconds =
        (baseMilliseconds * (0.5 / rate)).round().clamp(160, 3000).toInt();
    return Duration(milliseconds: estimatedMilliseconds);
  }
}

class _TtsWordSpan {
  const _TtsWordSpan({
    required this.start,
    required this.end,
    required this.displayIndex,
    required this.text,
  });

  final int start;
  final int end;
  final int displayIndex;
  final String text;
}
