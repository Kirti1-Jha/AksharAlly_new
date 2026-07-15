import 'package:flutter/material.dart';

import '../theme/accessibility_settings.dart';

/// Shows the "Customize Reading Experience" bottom sheet.
///
/// Extracted from ReaderScreen._showCustomizePanel (Phase 3A migration)
/// with no behavior changes: same sections, same sliders, same color-theme
/// grid, same accessibility toggles, same "Save as Default" behavior.
///
/// [onChanged] is invoked on every live edit inside the sheet (so the
/// caller can rebuild its own preview) and once more after the sheet
/// closes, matching ReaderScreen's original
/// `if (mounted) setState(() {})` post-close behavior.
Future<void> showReadingCustomizeSheet(
  BuildContext context, {
  required VoidCallback onChanged,
}) async {
  await showModalBottomSheet(
    context:            context,
    isScrollControlled: true,
    backgroundColor:    Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheet) {
          // update() modifies AccessibilitySettings, repaints the sheet, and
          // triggers the caller's rebuild so the text preview updates live.
          void update(VoidCallback fn) {
            setSheet(fn);
            onChanged();
          }

          final screenH = MediaQuery.of(ctx).size.height;

          return Container(
            height: screenH * 0.92,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Drag handle
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color:        Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                // Header
                Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(Icons.tune, color: Color(0xFF1565C0)),
                    const SizedBox(width: 8),
                    const Text(
                      'Customize Reading Experience',
                      style: TextStyle(
                        fontSize:   17,
                        fontWeight: FontWeight.w700,
                        color:      Color(0xFF1565C0),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Divider(height: 1),
                // Scrollable content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [

                      // ── FONT SELECTION ─────────────────────────────────
                      _sectionHeader('Font Family'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6, runSpacing: 6,
                        children: AccessibilitySettings.fonts.map((font) {
                          final sel = AccessibilitySettings.fontFamily == font;
                          final shortLabel = font == 'Atkinson Hyperlegible'
                              ? 'Atkinson'
                              : font;
                          return GestureDetector(
                            onTap: () => update(
                              () => AccessibilitySettings.fontFamily = font),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color:        sel
                                    ? const Color(0xFF1565C0)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border:       Border.all(
                                  color: sel
                                      ? const Color(0xFF1565C0)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                shortLabel,
                                style: TextStyle(
                                  color:      sel ? Colors.white : Colors.black87,
                                  fontWeight: sel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // ── FONT SIZE ─────────────────────────────────────
                      _sectionHeader(
                        'Font Size  •  '
                        '${AccessibilitySettings.fontSize.toStringAsFixed(0)}px',
                      ),
                      Slider(
                        value:     AccessibilitySettings.fontSize,
                        min:       14, max: 36,
                        divisions: 44,
                        onChanged: (v) => update(
                          () => AccessibilitySettings.fontSize = v),
                      ),

                      // ── LETTER SPACING ────────────────────────────────
                      _sectionHeader(
                        'Letter Spacing  •  '
                        '${AccessibilitySettings.letterSpacing.toStringAsFixed(1)}',
                      ),
                      Slider(
                        value:     AccessibilitySettings.letterSpacing,
                        min:       0, max: 3.0,
                        divisions: 30,
                        onChanged: (v) => update(
                          () => AccessibilitySettings.letterSpacing = v),
                      ),

                      // ── WORD SPACING ──────────────────────────────────
                      _sectionHeader(
                        'Word Spacing  •  '
                        '${AccessibilitySettings.wordSpacing.toStringAsFixed(1)}',
                      ),
                      Slider(
                        value:     AccessibilitySettings.wordSpacing,
                        min:       0, max: 8.0,
                        divisions: 16,
                        onChanged: (v) => update(
                          () => AccessibilitySettings.wordSpacing = v),
                      ),

                      // ── LINE HEIGHT ───────────────────────────────────
                      _sectionHeader(
                        'Line Height  •  '
                        '${AccessibilitySettings.lineHeight.toStringAsFixed(1)}×',
                      ),
                      Slider(
                        value:     AccessibilitySettings.lineHeight,
                        min:       1.0, max: 3.0,
                        divisions: 20,
                        onChanged: (v) => update(
                          () => AccessibilitySettings.lineHeight = v),
                      ),

                      // ── PARAGRAPH SPACING ─────────────────────────────
                      _sectionHeader(
                        'Paragraph Spacing  •  '
                        '${AccessibilitySettings.paragraphSpacing.toStringAsFixed(0)}px',
                      ),
                      Slider(
                        value:     AccessibilitySettings.paragraphSpacing,
                        min:       8, max: 32,
                        divisions: 24,
                        onChanged: (v) => update(
                          () => AccessibilitySettings.paragraphSpacing = v),
                      ),

                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),

                      // ── COLOR THEMES ──────────────────────────────────
                      _sectionHeader('Color Theme'),
                      const SizedBox(height: 10),
                      Builder(builder: (ctx2) {
                        final cardW =
                            (MediaQuery.of(ctx2).size.width - 48) / 2;
                        return Wrap(
                          spacing: 8, runSpacing: 8,
                          children: AccessibilitySettings.themeLabels.keys
                              .map((key) {
                            final bg   = AccessibilitySettings.previewBg(key);
                            final text =
                                AccessibilitySettings.previewText(key);
                            final sel  =
                                AccessibilitySettings.colorTheme == key;
                            return GestureDetector(
                              onTap: () => update(
                                () => AccessibilitySettings.colorTheme = key),
                              child: Container(
                                width:  cardW,
                                height: 52,
                                decoration: BoxDecoration(
                                  color:        bg,
                                  borderRadius: BorderRadius.circular(10),
                                  border:       Border.all(
                                    color: sel
                                        ? const Color(0xFF1565C0)
                                        : Colors.grey.shade300,
                                    width: sel ? 2.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (sel)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 4),
                                        child: Icon(Icons.check,
                                            color: text, size: 13),
                                      ),
                                    Text(
                                      AccessibilitySettings
                                          .themeLabels[key]!,
                                      style: TextStyle(
                                        color:      text,
                                        fontSize:   12,
                                        fontWeight: sel
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }),

                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 4),

                      // ── ACCESSIBILITY FEATURES ────────────────────────
                      _sectionHeader('Accessibility Features'),
                      _toggle(
                        'Word Highlighting during TTS',
                        AccessibilitySettings.wordHighlighting,
                        (v) => update(
                          () => AccessibilitySettings.wordHighlighting = v),
                      ),
                      _toggle(
                        'Focus Line Mode',
                        AccessibilitySettings.focusLineMode,
                        (v) => update(
                          () => AccessibilitySettings.focusLineMode = v),
                        subtitle: 'UI ready — coming soon',
                      ),
                      _toggle(
                        'Reading Ruler',
                        AccessibilitySettings.readingRuler,
                        (v) => update(
                          () => AccessibilitySettings.readingRuler = v),
                        subtitle: 'UI ready — coming soon',
                      ),
                      _toggle(
                        'Syllable Breakdown',
                        AccessibilitySettings.syllableBreakdown,
                        (v) => update(
                          () => AccessibilitySettings.syllableBreakdown = v),
                        subtitle: 'UI ready — coming soon',
                      ),
                      _toggle(
                        'Larger Touch Targets',
                        AccessibilitySettings.largerTouchTargets,
                        (v) => update(
                          () => AccessibilitySettings.largerTouchTargets = v),
                      ),
                      _toggle(
                        'Reduce Motion / Animations',
                        AccessibilitySettings.reduceMotion,
                        (v) => update(
                          () => AccessibilitySettings.reduceMotion = v),
                      ),

                      const SizedBox(height: 20),

                      // ── SAVE BUTTON ───────────────────────────────────
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

  // After the sheet closes, rebuild so the main screen reflects any changes
  // the user didn't explicitly save.
  onChanged();
}

// ── customize panel helpers ───────────────────────────────────────────────
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
            style: const TextStyle(fontSize: 11, color: Colors.grey))
        : null,
    value:     value,
    onChanged: onChanged,
    dense:     true,
  );
}
