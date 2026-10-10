import 'package:aksharally_ui/services/reading_text_segments.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReadingTextSegments', () {
    test('splits whitespace consistently and marks paragraph boundaries', () {
      expect(
        ReadingTextSegments.splitToWords(
          'पहिला\tशब्द\nदुसरा शब्द.\n\nपुढचा भाग.',
        ),
        [
          'पहिला',
          'शब्द',
          'दुसरा',
          'शब्द.',
          ReadingTextSegments.paragraphMarker,
          'पुढचा',
          'भाग.',
        ],
      );
    });

    test('finds the current Marathi sentence without crossing a paragraph', () {
      final words = ReadingTextSegments.splitToWords(
        'पहिले वाक्य संपले। दुसरे वाक्य सुरू आहे!\n\nतिसरा भाग.',
      );

      final range = ReadingTextSegments.sentenceAt(words, 4);

      expect(range?.firstWordIndex, 3);
      expect(range?.lastWordIndex, 6);
      expect(
        words
            .sublist(range!.firstWordIndex, range!.lastWordIndex + 1)
            .join(' '),
        'दुसरे वाक्य सुरू आहे!',
      );
    });

    test('resolves text after repeated tokens in their original order', () {
      const source = 'तो शब्द, तो शब्द पुन्हा. पुढचा भाग.';
      final words = ReadingTextSegments.splitToWords(source);
      final lastWordInSentence = words.indexOf('पुन्हा.');

      expect(
        ReadingTextSegments.textAfterWord(source, words, lastWordInSentence),
        'पुढचा भाग.',
      );
    });
  });
}
