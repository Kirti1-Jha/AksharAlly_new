import 'package:aksharally_ui/services/tts_progress_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TtsProgressMapper', () {
    test(
      'maps repeated words, punctuation, and paragraph spacing by range',
      () {
        const text = 'Wait, wait!\n\nनमस्ते world.';
        final mapper = TtsProgressMapper(
          text: text,
          displayWordIndices: const [1, 2, 4, 5],
          displayWords: const ['Wait,', 'wait!', 'नमस्ते', 'world.'],
        );

        expect(mapper.displayIndexForRange(0, 'Wait,'.length), 1);
        final repeatedWordStart = text.indexOf('wait!', 'Wait,'.length);
        expect(
          mapper.displayIndexForRange(
            repeatedWordStart,
            repeatedWordStart + 'wait!'.length,
          ),
          2,
        );
        final hindiStart = text.indexOf('नमस्ते');
        expect(
          mapper.displayIndexForRange(hindiStart, hindiStart + 'नमस्ते'.length),
          4,
        );
        final worldStart = text.indexOf('world.');
        expect(
          mapper.displayIndexForRange(worldStart, worldStart + 'world.'.length),
          5,
        );
      },
    );

    test(
      'maps multiple spoken tokens inside one displayed tab-separated word',
      () {
        const text = 'one\ttwo three';
        final mapper = TtsProgressMapper(
          text: text,
          displayWordIndices: const [7, 8],
          displayWords: const ['one\ttwo', 'three'],
        );
        final twoStart = text.indexOf('two');
        final threeStart = text.indexOf('three');

        expect(mapper.displayIndexForRange(0, 3), 7);
        expect(mapper.displayIndexForRange(twoStart, twoStart + 3), 7);
        expect(mapper.wordsForDisplayIndex(7), ['one', 'two']);
        expect(mapper.displayIndexForRange(threeStart, threeStart + 5), 8);
      },
    );

    test('identifies progress ranges that span multiple spoken words', () {
      const text = 'one two three';
      final mapper = TtsProgressMapper(
        text: text,
        displayWordIndices: const [0, 1, 2],
        displayWords: const ['one', 'two', 'three'],
      );

      expect(mapper.isCoarseProgressRange('one two', 0, 7), isTrue);
      expect(mapper.isCoarseProgressRange('one', 0, 3), isFalse);
    });

    test(
      'trusts a single-word range when callback text contains a phrase',
      () {
        final mapper = TtsProgressMapper(
          text: 'one two three',
          displayWordIndices: const [0, 1, 2],
        );

        expect(mapper.isCoarseProgressRange('one two', 0, 3), isFalse);
        expect(mapper.displayIndexForRange(0, 3), 0);
      },
    );
  });
}
