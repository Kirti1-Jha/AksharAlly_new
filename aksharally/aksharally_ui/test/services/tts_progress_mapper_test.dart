import 'package:aksharally_ui/services/tts_progress_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TtsProgressMapper', () {
    test('uses source offsets to distinguish repeated words and punctuation', () {
      const text = 'read read, then.';
      final mapper = TtsProgressMapper(
        text: text,
        displayWordIndices: const [3, 4, 5],
      );

      expect(mapper.displayIndexForRange(0, 4), 3);
      expect(mapper.displayIndexForRange(5, 10), 4);
      expect(mapper.displayIndexForRange(11, text.length), 5);
    });

    test(
      'maps Marathi Devanagari and supplementary Unicode by UTF-16 range',
      () {
        const text = 'मराठी भाषा वाचन 🌻';
        final mapper = TtsProgressMapper(
          text: text,
          displayWordIndices: const [0, 1, 2, 3],
        );
        final flowerStart = text.indexOf('🌻');

        expect(
          mapper.displayIndexForRange(flowerStart, flowerStart + '🌻'.length),
          3,
        );
        expect(
          mapper.displayIndexForRange(
            text.indexOf('भाषा'),
            text.indexOf('भाषा') + 'भाषा'.length,
          ),
          1,
        );
      },
    );

    test('recognizes whole-utterance callbacks as coarse progress', () {
      final mapper = TtsProgressMapper(
        text: 'एक वाक्य इथे आहे.',
        displayWordIndices: const [0, 1, 2, 3],
      );

      expect(mapper.isCoarseProgressWord('एक वाक्य इथे आहे.'), isTrue);
      expect(mapper.isCoarseProgressWord('वाक्य'), isFalse);
    });

    test('estimated fallback durations get shorter at faster rates', () {
      const word = 'वाचन';

      expect(
        TtsProgressMapper.estimateWordDuration(word, 0.2),
        greaterThan(TtsProgressMapper.estimateWordDuration(word, 0.8)),
      );
    });
  });
}
