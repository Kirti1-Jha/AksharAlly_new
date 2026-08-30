import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/accessibility_settings.dart';

/// Shows the "Customize Reading Experience" bottom sheet.
///
/// All changes are client-side only — they modify [AccessibilitySettings]
/// live and call [onChanged] so the caller can rebuild its own preview.
/// [AccessibilitySettings.save] is only called when the user taps
/// "Save as Default".
///
/// [onChanged] is also called once after the sheet closes to let the
/// caller pick up any unsaved changes.
Future<void> showReadingCustomizeSheet(
  BuildContext context, {
  required VoidCallback onChanged,
  String detectedText = '',
}) async {
  await showModalBottomSheet(
    context:            context,
    isScrollControlled: true,
    backgroundColor:    Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheet) {
          // update() — modify AccessibilitySettings, repaint sheet, notify
          // caller so the reading preview behind the sheet updates live.
          void update(VoidCallback fn) {
            setSheet(fn);
            onChanged();
          }

          final screenH  = MediaQuery.of(ctx).size.height;
          final largeTap = AccessibilitySettings.largerTouchTargets;

          return Container(
            height: screenH * 0.92,
            decoration: const BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // ── Drag handle ──────────────────────────────────────────
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color:        Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Header ───────────────────────────────────────────────
                Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(Icons.tune, color: Color(0xFF1565C0)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Customize Reading Experience',
                        style: TextStyle(
                          fontSize:   17,
                          fontWeight: FontWeight.w700,
                          color:      Color(0xFF1565C0),
                        ),
                      ),
                    ),
                    IconButton(
                      icon:      const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Divider(height: 1),

                // ── Scrollable content ───────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [

                      // ── FONT FAMILY ─────────────────────────────────────
                      _sectionHeader('Font Family'),
                      const SizedBox(height: 8),
                      _fontCategory(
                        'English Reading Fonts',
                        AccessibilitySettings.englishFonts,
                        update,
                        largeTap: largeTap,
                        recommended: !AccessibilitySettings
                            .isPrimarilyDevanagari(detectedText),
                        recommendedLabel: 'Recommended for English',
                      ),
                      const SizedBox(height: 14),
                      _fontCategory(
                        'Hindi & Marathi Fonts',
                        AccessibilitySettings.devanagariFonts,
                        update,
                        largeTap: largeTap,
                        recommended: AccessibilitySettings
                            .isPrimarilyDevanagari(detectedText),
                        recommendedLabel: 'Recommended for Hindi & Marathi',
                      ),
                      const SizedBox(height: 14),
                      _readingTestPanel(),

                      const SizedBox(height: 20),

                      // ── FONT SIZE ───────────────────────────────────────
                      _sectionHeader(
                        'Font Size  •  '
                        '${AccessibilitySettings.fontSize.toStringAsFixed(0)}px',
                      ),
                      Slider(
                        value:     AccessibilitySettings.fontSize,
                        min: 14, max: 36, divisions: 44,
                        onChanged: (v) => update(
                          () => AccessibilitySettings.fontSize = v),
                      ),

                      // ── LETTER SPACING ──────────────────────────────────
                      _sectionHeader(
                        'Letter Spacing  •  '
                        '${AccessibilitySettings.letterSpacing.toStringAsFixed(1)}',
                      ),
                      Slider(
                        value:     AccessibilitySettings.letterSpacing,
                        min: 0, max: 3.0, divisions: 30,
                        onChanged: (v) => update(
                          () => AccessibilitySettings.letterSpacing = v),
                      ),

                      // ── WORD SPACING ────────────────────────────────────
                      _sectionHeader(
                        'Word Spacing  •  '
                        '${AccessibilitySettings.wordSpacing.toStringAsFixed(1)}',
                      ),
                      Slider(
                        value:     AccessibilitySettings.wordSpacing,
                        min: 0, max: 8.0, divisions: 16,
                        onChanged: (v) => update(
                          () => AccessibilitySettings.wordSpacing = v),
                      ),

                      // ── LINE HEIGHT ─────────────────────────────────────
                      _sectionHeader(
                        'Line Height  •  '
                        '${AccessibilitySettings.lineHeight.toStringAsFixed(1)}×',
                      ),
                      Slider(
                        value:     AccessibilitySettings.lineHeight,
                        min: 1.0, max: 3.0, divisions: 20,
                        onChanged: (v) => update(
                          () => AccessibilitySettings.lineHeight = v),
                      ),

                      // ── PARAGRAPH SPACING ───────────────────────────────
                      _sectionHeader(
                        'Paragraph Spacing  •  '
                        '${AccessibilitySettings.paragraphSpacing.toStringAsFixed(0)}px',
                      ),
                      Slider(
                        value:     AccessibilitySettings.paragraphSpacing,
                        min: 8, max: 32, divisions: 24,
                        onChanged: (v) => update(
                          () => AccessibilitySettings.paragraphSpacing = v),
                      ),

                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),

                      // ── COLOR THEMES ────────────────────────────────────
                      _sectionHeader('Color Theme'),
                      const SizedBox(height: 10),

                      // Category → list of theme cards
                      ...AccessibilitySettings.themeCategories.entries
                          .map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _categoryHeader(entry.key),
                            ...entry.value.map((key) =>
                              _themeCard(key, update)),
                          ],
                        );
                      }),

                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 4),

                      // ── ACCESSIBILITY FEATURES ──────────────────────────
                      _sectionHeader('Accessibility Features'),

                      // Word Highlighting — always functional
                      _toggle(
                        'Word Highlighting during TTS',
                        AccessibilitySettings.wordHighlighting,
                        (v) => update(
                          () => AccessibilitySettings.wordHighlighting = v),
                      ),

                      // Focus Window — fully implemented in OutputScreen
                      _toggle(
                        'Focus Window',
                        AccessibilitySettings.focusLineMode,
                        (v) => update(
                          () => AccessibilitySettings.focusLineMode = v),
                        subtitle: 'Dims surrounding text; drag the handle to reposition.',
                      ),

                      // Reading Ruler — fully implemented in OutputScreen
                      _toggle(
                        'Reading Ruler',
                        AccessibilitySettings.readingRuler,
                        (v) => update(
                          () => AccessibilitySettings.readingRuler = v),
                        subtitle: 'Horizontal guide — drag to track your line.',
                      ),

                      // Syllable Breakdown (Experimental) — implemented in HighlightedTextView
                      _toggle(
                        'Syllable Breakdown (Experimental)',
                        AccessibilitySettings.syllableBreakdown,
                        (v) => update(
                          () => AccessibilitySettings.syllableBreakdown = v),
                        subtitle: 'Inserts visible breaks into words (e.g. read-ing, im-por-tant).',
                      ),

                      // Larger Touch Targets — applied to chips in OutputScreen
                      _toggle(
                        'Larger Touch Targets',
                        AccessibilitySettings.largerTouchTargets,
                        (v) => update(
                          () => AccessibilitySettings.largerTouchTargets = v),
                      ),

                      // Reduce Motion — removes transitions in reader overlays
                      _toggle(
                        'Reduce Motion / Animations',
                        AccessibilitySettings.reduceMotion,
                        (v) => update(
                          () => AccessibilitySettings.reduceMotion = v),
                      ),

                      const SizedBox(height: 20),

                      // ── SAVE BUTTON ─────────────────────────────────────
                      ElevatedButton.icon(
                        icon:  const Icon(Icons.save_outlined),
                        label: const Text('Save as Default'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          await AccessibilitySettings.save();
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  // After the sheet closes, rebuild so the main screen reflects any
  // live changes the user made but didn't explicitly save.
  onChanged();
}

// ── Theme card ─────────────────────────────────────────────────────────────

Widget _themeCard(String key, void Function(VoidCallback) update) {
  final sel   = AccessibilitySettings.colorTheme == key;
  final bg    = AccessibilitySettings.previewBg(key);
  final tc    = AccessibilitySettings.previewText(key);
  final label = AccessibilitySettings.themeLabels[key] ?? key;
  final desc  = AccessibilitySettings.themeDescriptions[key] ?? '';
  final badge = AccessibilitySettings.themeBadges[key];

  return GestureDetector(
    onTap: () => update(() => AccessibilitySettings.colorTheme = key),
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: sel ? const Color(0xFF1565C0) : Colors.grey.shade200,
          width: sel ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color:        sel
            ? const Color(0xFF1565C0).withOpacity(0.06)
            : Colors.grey.shade50,
      ),
      child: Row(
        children: [
          // ── Colour preview box ─────────────────────────────────────
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
              color:        bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aa',
                  style: TextStyle(
                    color: tc, fontSize: 18, fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'AksharAlly',
                  style: TextStyle(color: tc, fontSize: 7),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Info column ────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize:   13,
                          color:      Colors.black87,
                        ),
                      ),
                    ),
                    if (sel)
                      const Icon(Icons.check_circle,
                          size: 17, color: Color(0xFF1565C0)),
                  ],
                ),
                if (badge != null) ...[
                  const SizedBox(height: 4),
                  _badgePill(badge),
                ],
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 11,
                      color:    Colors.black54,
                      height:   1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // ── Sample preview text ────────────────────────────
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 5),
                  decoration: BoxDecoration(
                    color:        bg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: Colors.grey.shade200, width: 0.5),
                  ),
                  child: Text(
                    'AksharAlly helps make reading easier. '
                    'This is a sample reading preview.',
                    style: TextStyle(
                      color:    tc,
                      fontSize: 9,
                      height:   1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Category header ────────────────────────────────────────────────────────

Widget _categoryHeader(String category) {
  final icon = const {
    'Soft Reading':         Icons.auto_awesome_outlined,
    'High Contrast':        Icons.contrast,
    'Extreme Accessibility': Icons.accessibility_new,
    'Modern Reading':       Icons.nights_stay_outlined,
  };
  return Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Row(
      children: [
        Icon(
          icon[category] ?? Icons.palette_outlined,
          size:  15,
          color: const Color(0xFF1565C0),
        ),
        const SizedBox(width: 6),
        Text(
          category,
          style: const TextStyle(
            fontSize:   12,
            fontWeight: FontWeight.w700,
            color:      Color(0xFF1565C0),
            letterSpacing: 0.3,
          ),
        ),
      ],
    ),
  );
}

// ── Badge pill ─────────────────────────────────────────────────────────────

Widget _badgePill(String badge) {
  Color bg, fg;
  switch (badge) {
    case 'Dyslexia Recommended':
      bg = const Color(0xFFE8F5E9); fg = const Color(0xFF1B5E20); break;
    case 'High Contrast':
      bg = const Color(0xFF1565C0); fg = Colors.white; break;
    case 'Extreme Contrast':
      bg = const Color(0xFFE65100); fg = Colors.white; break;
    case 'Study Mode':
      bg = const Color(0xFFFFF3CD); fg = const Color(0xFF7B4F00); break;
    case 'Dark Mode':
      bg = const Color(0xFF263238); fg = Colors.white; break;
    default:
      bg = Colors.grey.shade200; fg = Colors.black87;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color:        bg,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      '⭐ $badge',
      style: TextStyle(
        fontSize:   9,
        fontWeight: FontWeight.w700,
        color:      fg,
      ),
    ),
  );
}

// ── Font chip label ────────────────────────────────────────────────────────

String _fontChipLabel(String font) {
  switch (font) {
    case 'Atkinson Hyperlegible': return 'Atkinson';
    case 'System Default':        return 'System';
    default:                      return font;
  }
}

// ── Language-aware font sections and previews ───────────────────────────────

Widget _fontCategory(
  String title,
  List<String> fonts,
  void Function(VoidCallback) update, {
  required bool largeTap,
  required bool recommended,
  required String recommendedLabel,
}) {
  final isDevanagari = title == 'Hindi & Marathi Fonts';
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1565C0),
          ),
        ),
      ),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: fonts.map((font) {
          final selected = AccessibilitySettings.fontFamily == font;
          final label = _fontChipLabel(font);
          final padH = largeTap ? 14.0 : 10.0;
          final padV = largeTap ? 9.0 : 6.0;
          return GestureDetector(
            onTap: () => update(
              () => AccessibilitySettings.fontFamily = font,
            ),
            child: Container(
              constraints: const BoxConstraints(minWidth: 92),
              padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF1565C0)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF1565C0)
                      : Colors.grey.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      fontSize: largeTap ? 13 : 12,
                    ),
                  ),
                  if (recommended) ...[
                    const SizedBox(height: 3),
                    _fontBadge(
                      recommendedLabel,
                      selected ? Colors.white : const Color(0xFF1B5E20),
                      selected
                          ? Colors.white.withOpacity(0.18)
                          : const Color(0xFFE8F5E9),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8FC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E8F2)),
        ),
        child: Text(
          isDevanagari
              ? 'हिंदी और मराठी पढ़ना अब आसान है।'
              : 'The quick brown fox jumps over the lazy dog.',
          style: _fontPreviewStyle(
            AccessibilitySettings.fontFamily,
            fontSize: isDevanagari ? 18 : 15,
            height: 1.35,
          ),
        ),
      ),
    ],
  );
}

Widget _fontBadge(String label, Color foreground, Color background) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      '⭐ $label',
      style: TextStyle(
        color: foreground,
        fontSize: 8,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

TextStyle _fontPreviewStyle(
  String font, {
  required double fontSize,
  required double height,
}) {
  final base = TextStyle(fontSize: fontSize, height: height);
  switch (font) {
    case 'OpenDyslexic':
      return base.copyWith(fontFamily: 'OpenDyslexic');
    case 'Lexend':
      return GoogleFonts.lexend(textStyle: base);
    case 'Atkinson Hyperlegible':
      return GoogleFonts.atkinsonHyperlegible(textStyle: base);
    case 'Noto Sans':
      return GoogleFonts.notoSans(textStyle: base);
    case 'Inter':
      return GoogleFonts.inter(textStyle: base);
    case 'Roboto':
      return GoogleFonts.roboto(textStyle: base);
    case 'Comic Neue':
      return GoogleFonts.comicNeue(textStyle: base);
    case 'Mukta':
      return GoogleFonts.mukta(textStyle: base).copyWith(
        fontFamilyFallback: const ['Noto Sans Devanagari'],
      );
    case 'Noto Sans Devanagari':
      return GoogleFonts.notoSansDevanagari(textStyle: base).copyWith(
        fontFamilyFallback: const ['Mukta'],
      );
    case 'Hind':
      return GoogleFonts.hind(textStyle: base).copyWith(
        fontFamilyFallback: const ['Mukta', 'Noto Sans Devanagari'],
      );
    case 'Baloo 2':
      return GoogleFonts.baloo2(textStyle: base).copyWith(
        fontFamilyFallback: const ['Mukta', 'Noto Sans Devanagari'],
      );
    case 'Tiro Devanagari Hindi':
      return GoogleFonts.tiroDevanagariHindi(textStyle: base).copyWith(
        fontFamilyFallback: const ['Mukta', 'Noto Sans Devanagari'],
      );
    case 'System Default':
      return base;
    default:
      return base.copyWith(
        fontFamily: font,
        fontFamilyFallback: const ['Lexend'],
      );
  }
}

Widget _readingTestPanel() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFBF0),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE9DFC7)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reading Test Preview',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'The quick brown fox jumps over the lazy dog.',
          style: _fontPreviewStyle(
            AccessibilitySettings.fontFamily,
            fontSize: 15,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'तेज़ भूरी लोमड़ी आलसी कुत्ते के ऊपर कूदती है।',
          style: _fontPreviewStyle(
            AccessibilitySettings.fontFamily,
            fontSize: 18,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'जलद तपकिरी कोल्हा आळशी कुत्र्यावर उडी मारतो.',
          style: _fontPreviewStyle(
            AccessibilitySettings.fontFamily,
            fontSize: 18,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

// ── Shared helpers ─────────────────────────────────────────────────────────

Widget _sectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      title,
      style: const TextStyle(
        fontSize:   13,
        fontWeight: FontWeight.w600,
        color:      Color(0xFF555555),
      ),
    ),
  );
}

Widget _toggle(
  String label,
  bool value,
  ValueChanged<bool> onChanged, {
  String? subtitle,
}) {
  return SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: const TextStyle(fontSize: 14)),
    subtitle: subtitle != null
        ? Text(subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.black54))
        : null,
    value:     value,
    onChanged: onChanged,
    dense:     true,
  );
}
