import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/accessibility_settings.dart';

/// Paragraph-aware, word-highlighting text renderer.
///
/// Extracted from ReaderScreen (Phase 3A migration) with no behavior
/// changes: same paragraph-marker splitting, same font resolution rules,
/// same highlight color/weight rules. Used by OutputScreen; ReaderScreen
/// keeps its own private copy untouched as rollback protection.
class HighlightedTextView extends StatelessWidget {
  /// Raw display text. Only used to detect the "empty" placeholder state —
  /// rendering itself uses [words].
  final String text;

  /// Pre-split word list (see [splitToWords]). Paragraph breaks are
  /// represented by [paragraphMarker] entries and are never rendered as
  /// text or spoken by TTS.
  final List<String> words;

  /// Index into [words] that should be highlighted (e.g. the word currently
  /// being spoken). Pass -1 for no highlight.
  final int currentIndex;

  const HighlightedTextView({
    super.key,
    required this.text,
    required this.words,
    required this.currentIndex,
  });

  /// Marks paragraph breaks in the words list (never spoken by TTS).
  static const String paragraphMarker = '¶';

  /// Splits raw text into a word list, converting `\n\n` into a paragraph
  /// marker and collapsing single `\n` into a space. Ported verbatim from
  /// ReaderScreen._splitToWords.
  static List<String> splitToWords(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\n\n', ' $paragraphMarker ')
        .replaceAll('\n', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
  }

  /// Returns a [TextStyle] using the font selected in AccessibilitySettings.
  /// OpenDyslexic gracefully falls back to Lexend (OD is not a Google Font).
  TextStyle _resolveFont({
    required double size,
    required double height,
    required double letterSp,
    required double wordSp,
    required Color color,
    FontWeight weight = FontWeight.normal,
  }) {
    final base = TextStyle(
      fontSize:      size,
      height:        height,
      letterSpacing: letterSp,
      wordSpacing:   wordSp,
      color:         color,
      fontWeight:    weight,
    );
    switch (AccessibilitySettings.fontFamily) {
      case 'Atkinson Hyperlegible':
        return GoogleFonts.atkinsonHyperlegible(textStyle: base);
      case 'Noto Sans':
        return GoogleFonts.notoSans(textStyle: base);
      case 'System Default':
        return base;
      case 'OpenDyslexic': // OD not in Google Fonts — fallback to Lexend
      case 'Lexend':
      default:
        return GoogleFonts.lexend(textStyle: base);
    }
  }

  Widget _wordWidget(int index, Color textColor) {
    final isHighlighted =
        index == currentIndex && AccessibilitySettings.wordHighlighting;
    return Text(
      words[index],
      style: _resolveFont(
        size:     AccessibilitySettings.fontSize,
        height:   AccessibilitySettings.lineHeight,
        letterSp: AccessibilitySettings.letterSpacing,
        wordSp:   AccessibilitySettings.wordSpacing,
        color:    isHighlighted ? Colors.red : textColor,
        weight:   isHighlighted ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = AccessibilitySettings.textColor();

    if (text.isEmpty) {
      return Text(
        'Formatted text will appear here...',
        style: _resolveFont(
          size:     AccessibilitySettings.fontSize,
          height:   AccessibilitySettings.lineHeight,
          letterSp: AccessibilitySettings.letterSpacing,
          wordSp:   AccessibilitySettings.wordSpacing,
          color:    textColor.withOpacity(0.5),
        ),
      );
    }

    final double wSpacing = AccessibilitySettings.wordSpacing;
    final double pSpacing = AccessibilitySettings.paragraphSpacing;

    final List<Widget> sections = [];
    List<Widget> currentParagraph = [];

    void flush() {
      if (currentParagraph.isNotEmpty) {
        sections.add(Wrap(
          spacing:    wSpacing,
          runSpacing: 4.0,
          children:   List.from(currentParagraph),
        ));
        currentParagraph = [];
      }
    }

    for (int i = 0; i < words.length; i++) {
      if (words[i] == paragraphMarker) {
        flush();
        sections.add(SizedBox(height: pSpacing));
      } else {
        currentParagraph.add(_wordWidget(i, textColor));
      }
    }
    flush();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize:       MainAxisSize.min,
      children:           sections,
    );
  }
}
