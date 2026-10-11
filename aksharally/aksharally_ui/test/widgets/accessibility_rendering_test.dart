import 'package:aksharally_ui/theme/accessibility_settings.dart';
import 'package:aksharally_ui/widgets/structured_content_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('StructuredContentView accessibility styles', () {
    tearDown(() => AccessibilitySettings.applyPreset('moderate'));

    testWidgets('preset typography and selected font render in OCR blocks',
        (tester) async {
      AccessibilitySettings.applyPreset('mild');
      AccessibilitySettings.fontFamily = 'Tahoma';

      Widget buildView() => MaterialApp(
            key: ValueKey(
              '${AccessibilitySettings.profile}_${AccessibilitySettings.fontFamily}_${AccessibilitySettings.fontSize}',
            ),
            home: Scaffold(
              body: StructuredContentView(
                content: {
                  'blocks': [
                    {'type': 'paragraph', 'text': 'Structured OCR text'},
                  ],
                },
              ),
            ),
          );

      await tester.pumpWidget(buildView());
      var text = tester.widget<Text>(find.text('Structured OCR text'));
      expect(text.style?.fontFamily, 'Tahoma');
      expect(text.style?.fontSize, 18);
      expect(text.style?.height, 1.5);
      expect(text.style?.letterSpacing, 0.5);
      expect(text.style?.wordSpacing, 2);

      AccessibilitySettings.applyPreset('moderate');
      AccessibilitySettings.fontFamily = 'Tahoma';
      await tester.pumpWidget(buildView());
      text = tester.widget<Text>(find.text('Structured OCR text'));
      expect(text.style?.fontFamily, 'Tahoma');
      expect(text.style?.fontSize, 22);
      expect(text.style?.height, 1.8);
      expect(text.style?.letterSpacing, 1);
      expect(text.style?.wordSpacing, 4);

      AccessibilitySettings.applyPreset('severe');
      await tester.pumpWidget(buildView());
      text = tester.widget<Text>(find.text('Structured OCR text'));
      expect(text.style?.fontFamily, 'OpenDyslexic');
      expect(text.style?.fontSize, 26);
      expect(text.style?.height, 2.2);
      expect(text.style?.letterSpacing, 1.5);
      expect(text.style?.wordSpacing, 6);

      AccessibilitySettings.applyPreset('mild');
      AccessibilitySettings.fontFamily = 'Tahoma';
      await tester.pumpWidget(buildView());
      text = tester.widget<Text>(find.text('Structured OCR text'));
      expect(text.style?.fontFamily, 'Tahoma');
      expect(text.style?.fontSize, 18);
    });

    testWidgets('custom font selection updates structured text style',
        (tester) async {
      AccessibilitySettings.profile = 'customize';
      AccessibilitySettings.fontFamily = 'Verdana';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructuredContentView(
              content: {
                'blocks': [
                  {'type': 'paragraph', 'text': 'Selected font'},
                ],
              },
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Selected font'));
      expect(text.style?.fontFamily, 'Verdana');
      expect(text.style?.fontSize, AccessibilitySettings.fontSize);
    });

    test('saved customization persists the selected font and other settings',
        () async {
      SharedPreferences.setMockInitialValues({});
      AccessibilitySettings.profile = 'customize';
      AccessibilitySettings.fontFamily = 'Mukta';
      AccessibilitySettings.fontSize = 28;
      AccessibilitySettings.colorTheme = 'black_yellow';

      await AccessibilitySettings.save();

      AccessibilitySettings.fontFamily = 'Verdana';
      AccessibilitySettings.fontSize = 18;
      AccessibilitySettings.colorTheme = 'cream_black';
      await AccessibilitySettings.load();

      expect(AccessibilitySettings.fontFamily, 'Mukta');
      expect(AccessibilitySettings.fontSize, 28);
      expect(AccessibilitySettings.colorTheme, 'black_yellow');
    });
  });
}
