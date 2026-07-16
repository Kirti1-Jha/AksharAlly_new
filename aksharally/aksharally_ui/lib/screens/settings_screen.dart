import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/app_settings.dart';
import '../theme/ui_accessibility.dart';
import '../services/library_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  // ── Local mirror of UIAccessibility (drives sliders / toggles / preview) ──
  String _fontFamily      = UIAccessibility.fontFamily;
  double _fontSize        = UIAccessibility.fontSize;
  double _letterSpacing   = UIAccessibility.letterSpacing;
  double _wordSpacing     = UIAccessibility.wordSpacing;
  double _lineHeight      = UIAccessibility.lineHeight;
  Color  _textColor       = UIAccessibility.textColor;
  Color  _bgColor         = UIAccessibility.backgroundColor;
  String _colorTheme      = UIAccessibility.activeColorTheme;
  String _profile         = UIAccessibility.activeProfile;
  bool   _boldText        = UIAccessibility.boldTextEnabled;
  bool   _highContrast    = UIAccessibility.highContrastEnabled;
  bool   _reduceAnim      = UIAccessibility.reducedAnimationsEnabled;
  bool   _largeTap        = UIAccessibility.largeTouchTargetsEnabled;
  String _language        = AppSettings.language;

  // ── Mutate helper ──────────────────────────────────────────────────────────
  void _change(void Function() mutate) {
    setState(mutate);
    UIAccessibility.notifier.value++;
    UIAccessibility.save();
  }

  // ── Section helpers ────────────────────────────────────────────────────────
  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.titleStyle),
            const SizedBox(height: AppTheme.spaceMD),
            child,
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SECTION 1 — Dyslexia Profiles
  // ════════════════════════════════════════════════════════════════════════════

  Widget _profileSection() {
    return _sectionCard(
      title: '🧠  Dyslexia Profiles',
      child: SizedBox(
        height: 158,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: UIAccessibility.profileLabels.keys.map(_profileCard).toList(),
        ),
      ),
    );
  }

  Widget _profileCard(String key) {
    final isActive = _profile == key;
    final label    = UIAccessibility.profileLabels[key]!;
    final desc     = UIAccessibility.profileDescriptions[key]!;

    // Profile preview colours
    Color previewBg   = UIAccessibility.themeBg('cream');
    Color previewText = UIAccessibility.themeText('cream');
    String previewFont = 'OpenDyslexic';
    switch (key) {
      case 'dyslexia':
        previewBg   = UIAccessibility.themeBg('cream');
        previewText = UIAccessibility.themeText('cream');
        previewFont = 'OpenDyslexic';
        break;
      case 'eye_strain':
        previewBg   = UIAccessibility.themeBg('soft_yellow');
        previewText = UIAccessibility.themeText('soft_yellow');
        previewFont = 'Inter';
        break;
      case 'clarity':
        previewBg   = UIAccessibility.themeBg('white');
        previewText = UIAccessibility.themeText('white');
        previewFont = 'Monospace';
        break;
      case 'beginner':
        previewBg   = UIAccessibility.themeBg('light_blue');
        previewText = UIAccessibility.themeText('light_blue');
        previewFont = 'OpenDyslexic';
        break;
    }

    return GestureDetector(
      onTap: () => _change(() {
        UIAccessibility.applyProfile(key);
        _syncFromModel();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width:  148,
        margin: const EdgeInsets.only(right: AppTheme.spaceSM),
        padding: const EdgeInsets.all(AppTheme.spaceSM),
        decoration: BoxDecoration(
          color:        isActive ? AppTheme.primaryBlue : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: isActive ? AppTheme.primaryBlue : Colors.grey.shade300,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // mini preview swatch
            Container(
              width:  double.infinity,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color:        previewBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Aa',
                style: TextStyle(
                  fontFamily:   previewFont,
                  fontSize:     22,
                  color:        previewText,
                  fontWeight:   FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize:   12,
                color:      isActive ? Colors.white : AppTheme.textDark,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: TextStyle(
                fontSize: 10,
                color:    isActive
                    ? Colors.white.withOpacity(0.85)
                    : AppTheme.textMuted,
              ),
              maxLines: 2,
            ),
            const Spacer(),
            Container(
              width:   double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color:        isActive
                    ? Colors.white.withOpacity(0.25)
                    : AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  isActive ? 'Active' : 'Apply',
                  style: TextStyle(
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    color:      Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SECTION 2 — Typography
  // ════════════════════════════════════════════════════════════════════════════

  Widget _typographySection() {
    return _sectionCard(
      title: '🔤  Typography',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Font Family',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: AppTheme.spaceSM),
          _fontChips(),
          const SizedBox(height: AppTheme.spaceMD),
          _slider(
            label: 'Font Size',
            value: _fontSize,
            min: 12, max: 22, divisions: 10,
            display: _fontSize.toStringAsFixed(0),
            onChanged: (v) => _change(() {
              _fontSize = v;
              UIAccessibility.fontSize = v;
            }),
          ),
          _slider(
            label: 'Letter Spacing',
            value: _letterSpacing,
            min: 0.0, max: 2.5, divisions: 10,
            display: _letterSpacing.toStringAsFixed(1),
            onChanged: (v) => _change(() {
              _letterSpacing = v;
              UIAccessibility.letterSpacing = v;
            }),
          ),
          _slider(
            label: 'Word Spacing',
            value: _wordSpacing,
            min: 0.0, max: 8.0, divisions: 8,
            display: _wordSpacing.toStringAsFixed(1),
            onChanged: (v) => _change(() {
              _wordSpacing = v;
              UIAccessibility.wordSpacing = v;
            }),
          ),
          _slider(
            label: 'Line Height',
            value: _lineHeight,
            min: 1.0, max: 3.0, divisions: 10,
            display: _lineHeight.toStringAsFixed(1),
            onChanged: (v) => _change(() {
              _lineHeight = v;
              UIAccessibility.lineHeight = v;
            }),
          ),
        ],
      ),
    );
  }

  Widget _fontChips() {
    return Wrap(
      spacing: AppTheme.spaceSM,
      runSpacing: AppTheme.spaceSM,
      children: UIAccessibility.fonts.map((name) {
        final active = _fontFamily == name;
        final preview = UIAccessibility.previewStyleFor(name);
        return GestureDetector(
          onTap: () => _change(() {
            _fontFamily = name;
            UIAccessibility.fontFamily = name;
            UIAccessibility.activeProfile = 'custom';
            _profile = 'custom';
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMD, vertical: AppTheme.spaceSM),
            decoration: BoxDecoration(
              color:        active ? AppTheme.primaryBlue : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(
                color: active ? AppTheme.primaryBlue : Colors.grey.shade300,
              ),
            ),
            child: Text(
              name,
              style: preview.copyWith(
                color:      active ? Colors.white : AppTheme.textDark,
                fontSize:   13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color:        AppTheme.accentCream,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(display,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue)),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor:   AppTheme.primaryBlue,
            inactiveTrackColor: AppTheme.primaryBlue.withOpacity(0.2),
            thumbColor:         AppTheme.primaryBlue,
            overlayColor:       AppTheme.primaryBlue.withOpacity(0.08),
            trackHeight:        3,
          ),
          child: Slider(
            value:     value.clamp(min, max),
            min:       min,
            max:       max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SECTION 3 — Color Themes
  // ════════════════════════════════════════════════════════════════════════════

  Widget _colorThemeSection() {
    final themes = UIAccessibility.colorThemeLabels;
    return _sectionCard(
      title: '🎨  Colour Themes',
      child: Wrap(
        spacing: AppTheme.spaceSM,
        runSpacing: AppTheme.spaceSM,
        children: themes.keys.map((key) {
          final active = _colorTheme == key;
          final bg     = UIAccessibility.themeBg(key);
          final tc     = UIAccessibility.themeText(key);
          final label  = themes[key]!;
          return GestureDetector(
            onTap: () => _change(() {
              _colorTheme = key;
              _textColor  = tc;
              _bgColor    = bg;
              UIAccessibility.activeColorTheme = key;
              UIAccessibility.textColor        = tc;
              UIAccessibility.backgroundColor  = bg;
              UIAccessibility.activeProfile    = 'custom';
              _profile = 'custom';
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width:   (MediaQuery.of(context).size.width - 120) / 2,
              padding: const EdgeInsets.all(AppTheme.spaceSM),
              decoration: BoxDecoration(
                color:        bg,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(
                  color: active ? AppTheme.primaryBlue : Colors.grey.shade300,
                  width: active ? 2.5 : 1,
                ),
                boxShadow: active
                    ? [BoxShadow(
                        color:      AppTheme.primaryBlue.withOpacity(0.25),
                        blurRadius: 6,
                        offset:     const Offset(0, 3),
                      )]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aa',
                      style: TextStyle(
                          fontFamily: 'OpenDyslexic',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: tc)),
                  const SizedBox(height: 4),
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: tc)),
                  if (active)
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.check_circle,
                          size: 16, color: AppTheme.primaryBlue),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SECTION 4 — Custom Appearance
  // ════════════════════════════════════════════════════════════════════════════

  Widget _customAppearanceSection() {
    return _sectionCard(
      title: '✏️  Custom Appearance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Text Colour',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: AppTheme.spaceSM),
          _swatchRow(
            swatches: UIAccessibility.textSwatches,
            selected: _textColor,
            onSelect: (c) => _change(() {
              _textColor = c;
              UIAccessibility.textColor  = c;
              UIAccessibility.activeProfile = 'custom';
              UIAccessibility.activeColorTheme = 'custom';
              _profile    = 'custom';
              _colorTheme = 'custom';
            }),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          const Text('Background Colour',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: AppTheme.spaceSM),
          _swatchRow(
            swatches: UIAccessibility.bgSwatches,
            selected: _bgColor,
            onSelect: (c) => _change(() {
              _bgColor = c;
              UIAccessibility.backgroundColor = c;
              UIAccessibility.activeProfile    = 'custom';
              UIAccessibility.activeColorTheme = 'custom';
              _profile    = 'custom';
              _colorTheme = 'custom';
            }),
          ),
        ],
      ),
    );
  }

  Widget _swatchRow({
    required List<Color> swatches,
    required Color selected,
    required ValueChanged<Color> onSelect,
  }) {
    return Wrap(
      spacing: AppTheme.spaceSM,
      runSpacing: AppTheme.spaceSM,
      children: swatches.map((c) {
        final isSelected = selected.value == c.value;
        return GestureDetector(
          onTap: () => onSelect(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 36, height: 36,
            decoration: BoxDecoration(
              color:  c,
              shape:  BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(
                      color:      AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 6,
                    )]
                  : [],
            ),
            child: isSelected
                ? Icon(Icons.check,
                    size: 16,
                    color: c.computeLuminance() < 0.5
                        ? Colors.white
                        : Colors.black)
                : null,
          ),
        );
      }).toList(),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SECTION 5 — Accessibility Toggles
  // ════════════════════════════════════════════════════════════════════════════

  Widget _toggleSection() {
    return _sectionCard(
      title: '♿  Accessibility Options',
      child: Column(
        children: [
          _toggle(
            icon:  Icons.format_bold,
            label: 'Bold UI Text',
            value: _boldText,
            onChanged: (v) => _change(() {
              _boldText = v;
              UIAccessibility.boldTextEnabled = v;
            }),
          ),
          _toggle(
            icon:  Icons.animation,
            label: 'Reduced Animations',
            value: _reduceAnim,
            onChanged: (v) => _change(() {
              _reduceAnim = v;
              UIAccessibility.reducedAnimationsEnabled = v;
            }),
          ),
          _toggle(
            icon:  Icons.touch_app_outlined,
            label: 'Larger Touch Targets',
            value: _largeTap,
            onChanged: (v) => _change(() {
              _largeTap = v;
              UIAccessibility.largeTouchTargetsEnabled = v;
            }),
          ),
          _toggle(
            icon:  Icons.contrast,
            label: 'High Contrast Mode',
            value: _highContrast,
            onChanged: (v) => _change(() {
              _highContrast = v;
              UIAccessibility.highContrastEnabled = v;
            }),
          ),
          const Divider(height: AppTheme.spaceLG),
          // Language selector (kept separate — feeds AppSettings.language for OCR)
          Row(
            children: [
              const Icon(Icons.language, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: AppTheme.spaceSM),
              const Expanded(
                child: Text('Language',
                    style: TextStyle(fontWeight: FontWeight.w500)),
              ),
              _langChip('English', 'en'),
              const SizedBox(width: 6),
              _langChip('हिंदी', 'hi'),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSM),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon:  const Icon(Icons.refresh, size: 18),
              label: const Text('Reset to Default'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                side: const BorderSide(color: AppTheme.primaryBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                UIAccessibility.reset();
                setState(_syncFromModel);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryBlue),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Switch(
            value:     value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _langChip(String label, String code) {
    final sel = _language == code;
    return GestureDetector(
      onTap: () => setState(() {
        _language = code;
        AppSettings.language = code;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color:        sel ? AppTheme.primaryBlue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        child: Text(label,
            style: TextStyle(
                color:      sel ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
                fontSize:   13)),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SECTION 6 — Live Preview + OpenDyslexic Font Test
  // ════════════════════════════════════════════════════════════════════════════

  Widget _livePreviewSection() {
    // Build a TextStyle for the preview using the CURRENT local state,
    // so it updates instantly as any slider or toggle changes.
    // previewStyleFor() resolves the correct fontFamily / Google Font for the
    // chosen font name; copyWith applies current size, weight, spacing, colour.
    TextStyle _pts(double size, FontWeight w) {
      return UIAccessibility.previewStyleFor(_fontFamily).copyWith(
        fontSize:           size,
        fontWeight:         _boldText ? FontWeight.bold : w,
        color:              _textColor,
        letterSpacing:      _letterSpacing,
        wordSpacing:        _wordSpacing,
        height:             _lineHeight,
        fontFamilyFallback: const ['Noto Sans', 'sans-serif'],
      );
    }

    return _sectionCard(
      title: '👁️  Live Preview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This preview reflects your current settings in real time. '
            'It also confirms OpenDyslexic is rendering correctly.',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            decoration: BoxDecoration(
              color:        _bgColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AksharAlly',
                    style: _pts(_fontSize + 6, FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Welcome Back',
                    style: _pts(_fontSize - 1, FontWeight.w500)
                        .copyWith(color: _textColor.withOpacity(0.7))),
                const SizedBox(height: AppTheme.spaceMD),
                _previewRow(Icons.book_outlined,        'Continue Reading', _pts(_fontSize, FontWeight.w600)),
                _previewRow(Icons.add_circle_outline,   'New Reading',      _pts(_fontSize, FontWeight.w600)),
                _previewRow(Icons.auto_stories_outlined, 'Library',          _pts(_fontSize, FontWeight.w600)),
                _previewRow(Icons.settings_outlined,    'Settings',         _pts(_fontSize, FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          // Font identification badge
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                'Font: $_fontFamily  ·  Size: ${_fontSize.toStringAsFixed(0)}  '
                '·  Theme: ${UIAccessibility.colorThemeLabels[_colorTheme] ?? _colorTheme}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewRow(IconData icon, String label, TextStyle ts) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _textColor.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(label, style: ts),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // READING HISTORY
  // ════════════════════════════════════════════════════════════════════════════

  Widget _readingHistorySection() {
    return _sectionCard(
      title: '📚  Reading History',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${LibraryStorage.getItems().length} saved readings',
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon:  const Icon(Icons.delete_sweep_outlined,
                  color: Colors.redAccent),
              label: const Text('Clear Reading History',
                  style: TextStyle(color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                side:    const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape:   RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
              ),
              onPressed: _confirmClearHistory,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearHistory() async {
    final count = LibraryStorage.getItems().length;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reading history is already empty.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear reading history?'),
        content: Text(
          'This will permanently delete all $count saved '
          '${count == 1 ? 'reading' : 'readings'}. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      LibraryStorage.clearAll();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reading history cleared.')),
      );
    }
  }

  // ── Sync local state from UIAccessibility static fields ───────────────────
  void _syncFromModel() {
    _fontFamily    = UIAccessibility.fontFamily;
    _fontSize      = UIAccessibility.fontSize;
    _letterSpacing = UIAccessibility.letterSpacing;
    _wordSpacing   = UIAccessibility.wordSpacing;
    _lineHeight    = UIAccessibility.lineHeight;
    _textColor     = UIAccessibility.textColor;
    _bgColor       = UIAccessibility.backgroundColor;
    _colorTheme    = UIAccessibility.activeColorTheme;
    _profile       = UIAccessibility.activeProfile;
    _boldText      = UIAccessibility.boldTextEnabled;
    _highContrast  = UIAccessibility.highContrastEnabled;
    _reduceAnim    = UIAccessibility.reducedAnimationsEnabled;
    _largeTap      = UIAccessibility.largeTouchTargetsEnabled;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Screen header
        Text('Accessibility Center', style: AppTheme.titleStyle.copyWith(color: Colors.white)),
        const SizedBox(height: 4),
        Text(
          'Customise how AksharAlly looks — settings apply across the entire app.',
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
        ),
        const SizedBox(height: AppTheme.spaceMD),

        _profileSection(),
        _typographySection(),
        _colorThemeSection(),
        _customAppearanceSection(),
        _toggleSection(),
        _livePreviewSection(),
        _readingHistorySection(),

        const SizedBox(height: AppTheme.spaceXL),
      ],
    );
  }
}
