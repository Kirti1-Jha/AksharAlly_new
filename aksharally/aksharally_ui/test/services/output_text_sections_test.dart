import 'package:flutter_test/flutter_test.dart';
import 'package:aksharally_ui/services/output_text_sections.dart';

void main() {
  group('OutputTextSections.paginate', () {
    test('keeps source text contiguous and prefers paragraph boundaries', () {
      final firstParagraph = List.generate(125, (i) => 'first$i').join(' ');
      final secondParagraph = List.generate(125, (i) => 'second$i').join(' ');
      final text = '$firstParagraph\n\n$secondParagraph';
      final words = List.generate(250, (i) => i);

      final sections = OutputTextSections.paginate(
        text: text,
        spokenWordIndices: words,
        maxWordsPerSection: 180,
      );

      expect(sections, hasLength(2));
      expect(sections.map((section) => section.text).join(), text);
      expect(sections.first.text, '$firstParagraph\n\n');
      expect(sections.first.startWordIndex, 0);
      expect(sections.first.endWordIndex, 125);
      expect(sections.last.startWordIndex, 125);
      expect(sections.last.endWordIndex, 250);
    });

    test('splits a long paragraph without dropping or duplicating text', () {
      final text = List.generate(401, (i) => 'word$i').join(' ');
      final sections = OutputTextSections.paginate(
        text: text,
        spokenWordIndices: List.generate(401, (i) => i),
        maxWordsPerSection: 180,
      );

      expect(sections, hasLength(3));
      expect(sections.map((section) => section.text).join(), text);
      expect(sections.map((section) => section.endWordIndex - section.startWordIndex), [
        180,
        180,
        41,
      ]);
    });

    test('does not paginate text that fits in one section', () {
      const text = 'Keep  every\nspace and\n\nparagraph.';
      final sections = OutputTextSections.paginate(
        text: text,
        spokenWordIndices: List.generate(5, (i) => i),
      );

      expect(sections, hasLength(1));
      expect(sections.single.text, text);
    });
  });
}
