import 'package:flutter/material.dart';
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

  // ── Pending (preview-only) state ──────────────────────────────────────────
  // None of these write to UIAccessibility until _applyChanges() is called.
  String _pendingFont      = UIAccessibility.fontFamily;
  double _pendingSize      = UIAccessibility.fontSize;
  double _pendingLetterSp  = UIAccessibility.letterSpacing;
  double _pendingWordSp    = UIAccessibility.wordSpacing;
  double _pendingLineH     = UIAccessibility.lineHeight;
  Color  _pendingTextColor = UIAccessibility.textColor;
  Color  _pendingBgColor   = UIAccessibility.backgroundColor;
  String _pendingTheme     = UIAccessibility.activeColorTheme;
  String _pendingProfile   = UIAccessibility.activeProfile;
  bool   _pendingBold      = UIAccessibility.boldTextEnabled;
  bool   _pendingContrast  = UIAccessibility.highContrastEnabled;
  bool   _pendingAnim      = UIAccessibility.reducedAnimationsEnabled;
  bool   _pendingLargeTap  = UIAccessibility.largeTouchTargetsEnabled;

  // Dirty flag — true whenever pending differs from applied
  bool _hasPendingChanges = false;

  // Language applies immediately (OCR-only, not a UI preview setting)
  String _language = AppSettings.language;

  // ── Pending mutate helper (preview-only — does NOT touch UIAccessibility) ──
  void _preview(void Function() mutate) {
    setState(() {
      mutate();
      _hasPendingChanges = true;
    });
  }

  // ── Pending profile apply ─────────────────────────────────────────────────
  void _pendingApplyProfile(String key) {
    _preview(() {
      _pendingProfile = key;
      switch (key) {
        case 'dyslexia':
          _pendingFont      = 'OpenDyslexic';
          _pendingSize      = 15.0;
          _pendingLetterSp  = 0.3;
          _pendingWordSp    = 2.0;
          _pendingLineH     = 1.6;
          _pendingTheme     = 'cream_black';
          _pendingTextColor = const Color(0xFF111111);
          _pendingBgColor   = const Color(0xFFF5F1E6);
          break;
        case 'eye_strain':
          _pendingFont      = 'Inter';
          _pendingSize      = 14.0;
          _pendingLetterSp  = 0.2;
          _pendingWordSp    = 1.5;
          _pendingLineH     = 1.5;
          _pendingTheme     = 'soft_yellow_black';
          _pendingTextColor = const Color(0xFF111111);
          _pendingBgColor   = const Color(0xFFFFF8C6);
          break;
        case 'clarity':
          _pendingFont      = 'Monospace';
          _pendingSize      = 16.0;
          _pendingLetterSp  = 0.5;
          _pendingWordSp    = 3.0;
          _pendingLineH     = 1.8;
          _pendingTheme     = 'white_black';
          _pendingTextColor = const Color(0xFF000000);
          _pendingBgColor   = const Color(0xFFFFFFFF);
          break;
        case 'beginner':
          _pendingFont      = 'OpenDyslexic';
          _pendingSize      = 18.0;
          _pendingLetterSp  = 0.5;
          _pendingWordSp    = 4.0;
          _pendingLineH     = 2.0;
          _pendingTheme     = 'pale_blue_navy';
          _pendingTextColor = const Color(0xFF001F54);
          _pendingBgColor   = const Color(0xFFDCEEFF);
          break;
      }
    });
  }

  // ── Apply pending → UIAccessibility (global) ──────────────────────────────
  void _applyChanges() {
    UIAccessibility.fontFamily               = _pendingFont;
    UIAccessibility.fontSize                 = _pendingSize;
    UIAccessibility.letterSpacing            = _pendingLetterSp;
    UIAccessibility.wordSpacing              = _pendingWordSp;
    UIAccessibility.lineHeight               = _pendingLineH;
    UIAccessibility.textColor                = _pendingTextColor;
    UIAccessibility.backgroundColor          = _pendingBgColor;
    UIAccessibility.activeColorTheme         = _pendingTheme;
    UIAccessibility.activeProfile            = _pendingProfile;
    UIAccessibility.boldTextEnabled          = _pendingBold;
    UIAccessibility.highContrastEnabled      = _pendingContrast;
    UIAccessibility.reducedAnimationsEnabled = _pendingAnim;
    UIAccessibility.largeTouchTargetsEnabled = _pendingLargeTap;
    UIAccessibility.notifier.value++;
    UIAccessibility.save();
    setState(() => _hasPendingChanges = false);
  }

  // ── Reset preview to current applied values ───────────────────────────────
  void _resetPreview() {
    setState(() {
      _pendingFont      = UIAccessibility.fontFamily;
      _pendingSize      = UIAccessibility.fontSize;
      _pendingLetterSp  = UIAccessibility.letterSpacing;
      _pendingWordSp    = UIAccessibility.wordSpacing;
      _pendingLineH     = UIAccessibility.lineHeight;
      _pendingTextColor = UIAccessibility.textColor;
      _pendingBgColor   = UIAccessibility.backgroundColor;
      _pendingTheme     = UIAccessibility.activeColorTheme;
      _pendingProfile   = UIAccessibility.activeProfile;
      _pendingBold      = UIAccessibility.boldTextEnabled;
      _pendingContrast  = UIAccessibility.highContrastEnabled;
      _pendingAnim      = UIAccessibility.reducedAnimationsEnabled;
      _pendingLargeTap  = UIAccessibility.largeTouchTargetsEnabled;
      _hasPendingChanges = false;
    });
  }

  // ── Card background — adapts for dark custom themes ───────────────────────
  Color get _cardBg {
    final bg = UIAccessibility.backgroundColor;
    return bg.computeLuminance() < 0.3
        ? const Color(0xFF2E2E2E)
        : Colors.white;
  }

  Color get _cardText {
    final bg = UIAccessibility.backgroundColor;
    return bg.computeLuminance() < 0.3
        ? Colors.white
        : UIAccessibility.textColor;
  }

  // ── Screen header colour — contrast against the BACKGROUND ───────────────
  // Uses backgroundColor luminance (not textColor luminance) so the title
  // is always readable regardless of which theme is applied.
  Color get _headerColor {
    return UIAccessibility.backgroundColor.computeLuminance() > 0.3
        ? UIAccessibility.textColor
        : Colors.white;
  }

  // ── WCAG contrast ratio between foreground and background ─────────────────
  double _contrastRatio(Color fg, Color bg) {
    final l1 = fg.computeLuminance();
    final l2 = bg.computeLuminance();
    final lighter = l1 > l2 ? l1 : l2;
    final darker  = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  // ── Badge pill widget ─────────────────────────────────────────────────────
  Widget _badgePill(String badge, {double fontSize = 8.5}) {
    final Color badgeBg;
    final Color badgeFg;
    if (badge == 'Most Popular') {
      badgeBg = const Color(0xFFFFF3CD);
      badgeFg = const Color(0xFF7B4F00);
    } else if (badge == 'High Contrast') {
      badgeBg = const Color(0xFF1565C0);
      badgeFg = Colors.white;
    } else {
      // 'Dyslexia Recommended' and any future badge
      badgeBg = const Color(0xFFE8F5E9);
      badgeFg = const Color(0xFF1B5E20);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:        badgeBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        '⭐ $badge',
        style: TextStyle(
          fontSize:   fontSize,
          fontWeight: FontWeight.w700,
          color:      badgeFg,
        ),
      ),
    );
  }

  // ── Section card container ────────────────────────────────────────────────
  Widget _sectionCard({
    required String title,
    String? description,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize:   17,
                fontWeight: FontWeight.w800,
                color:      _cardText,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color:    _cardText.withOpacity(0.6),
                  height:   1.4,
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spaceMD),
            child,
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ACTION BANNER — shown at top when preview differs from applied
  // ════════════════════════════════════════════════════════════════════════════

  Widget _actionBanner() {
    if (!_hasPendingChanges) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMD, vertical: 12),
      decoration: BoxDecoration(
        color:        const Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.18),
            blurRadius: 10,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white70, size: 16),
              SizedBox(width: 6),
              Text(
                'Changes not yet applied',
                style: TextStyle(
                  color:      Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize:   13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'The Live Preview below reflects your selections. '
            'Press Apply Changes to update the entire app.',
            style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetPreview,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull),
                    ),
                  ),
                  child: const Text('Reset Preview',
                      style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Apply Changes',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SECTION 1 — Dyslexia Profiles
  // ════════════════════════════════════════════════════════════════════════════

  Widget _profileSection() {
    return _sectionCard(
      title:       '🧠  Dyslexia Profiles',
      description: 'Choose a starting point optimised for your accessibility needs.',
      child: SizedBox(
        height: 205,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: UIAccessibility.profileLabels.keys
              .map(_profileCard)
              .toList(),
        ),
      ),
    );
  }

  Widget _profileCard(String key) {
    final isPending = _pendingProfile == key;
    final isApplied = UIAccessibility.activeProfile == key;
    final label     = UIAccessibility.profileLabels[key]!;
    final desc      = UIAccessibility.profileDescriptions[key]!;
    final badge     = UIAccessibility.profileBadges[key];

    // Use the new theme keys for preview colours.
    final String themeKey;
    switch (key) {
      case 'dyslexia':   themeKey = 'cream_black';       break;
      case 'eye_strain': themeKey = 'soft_yellow_black'; break;
      case 'clarity':    themeKey = 'white_black';        break;
      case 'beginner':
      default:           themeKey = 'pale_blue_navy';     break;
    }
    final previewBg   = UIAccessibility.themeBg(themeKey);
    final previewText = UIAccessibility.themeText(themeKey);

    // OpenDyslexic for dyslexia/beginner, Inter for eye_strain, Monospace for clarity
    final String previewFont;
    switch (key) {
      case 'eye_strain': previewFont = 'Inter';        break;
      case 'clarity':    previewFont = 'RobotoMono';   break;
      default:           previewFont = 'OpenDyslexic'; break;
    }

    final cardColor  = isPending ? AppTheme.primaryBlue : Colors.grey.shade100;
    final textOnCard = isPending ? Colors.white : AppTheme.textDark;

    String buttonLabel;
    Color  buttonBg;
    if (isApplied && !isPending) {
      buttonLabel = '✓ Applied';
      buttonBg    = AppTheme.primaryBlue.withOpacity(0.15);
    } else if (isPending && !isApplied) {
      buttonLabel = 'Previewing';
      buttonBg    = Colors.white.withOpacity(0.25);
    } else if (isPending) {
      buttonLabel = '✓ Applied';
      buttonBg    = Colors.white.withOpacity(0.25);
    } else {
      buttonLabel = 'Select';
      buttonBg    = AppTheme.primaryBlue;
    }

    return GestureDetector(
      onTap: () => _pendingApplyProfile(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width:   152,
        margin:  const EdgeInsets.only(right: AppTheme.spaceSM),
        padding: const EdgeInsets.all(AppTheme.spaceSM),
        decoration: BoxDecoration(
          color:        cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: isPending ? AppTheme.primaryBlue : Colors.grey.shade300,
            width: isPending ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge (dyslexia profile only)
            if (badge != null) ...[
              _badgePill(badge),
              const SizedBox(height: 5),
            ],

            // Mini preview swatch
            Container(
              width:   double.infinity,
              height:  40,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color:        previewBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Aa',
                style: TextStyle(
                  fontFamily: previewFont,
                  fontSize:   21,
                  color:      previewText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize:   11,
                  color:      textOnCard),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                desc,
                style: TextStyle(
                    fontSize: 9.5,
                    color:    isPending
                        ? Colors.white.withOpacity(0.8)
                        : AppTheme.textMuted,
                    height:   1.3),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width:   double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color:        buttonBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  buttonLabel,
                  style: TextStyle(
                    fontSize:   10,
                    fontWeight: FontWeight.w700,
                    color:      isPending
                        ? Colors.white
                        : (isApplied ? AppTheme.primaryBlue : Colors.white),
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
      title:       '🔤  Typography',
      description: 'Adjust fonts and spacing so text is comfortable to read.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Font Family',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize:   13,
                  color:      _cardText)),
          const SizedBox(height: AppTheme.spaceSM),
          _fontChips(),
          const SizedBox(height: AppTheme.spaceMD),
          _slider(
            label:     'Font Size',
            value:     _pendingSize,
            min: 12, max: 22, divisions: 10,
            display:   _pendingSize.toStringAsFixed(0),
            onChanged: (v) => _preview(() => _pendingSize = v),
          ),
          _slider(
            label:     'Letter Spacing',
            value:     _pendingLetterSp,
            min: 0.0, max: 2.5, divisions: 10,
            display:   _pendingLetterSp.toStringAsFixed(1),
            onChanged: (v) => _preview(() => _pendingLetterSp = v),
          ),
          _slider(
            label:     'Word Spacing',
            value:     _pendingWordSp,
            min: 0.0, max: 8.0, divisions: 8,
            display:   _pendingWordSp.toStringAsFixed(1),
            onChanged: (v) => _preview(() => _pendingWordSp = v),
          ),
          _slider(
            label:     'Line Height',
            value:     _pendingLineH,
            min: 1.0, max: 3.0, divisions: 10,
            display:   _pendingLineH.toStringAsFixed(1),
            onChanged: (v) => _preview(() => _pendingLineH = v),
          ),
        ],
      ),
    );
  }

  Widget _fontChips() {
    return Wrap(
      spacing:    AppTheme.spaceSM,
      runSpacing: AppTheme.spaceSM,
      children:   UIAccessibility.fonts.map((name) {
        final active  = _pendingFont == name;
        final preview = UIAccessibility.previewStyleFor(name);
        return GestureDetector(
          onTap: () => _preview(() {
            _pendingFont    = name;
            _pendingProfile = 'custom';
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
                color:      active ? Colors.white : _cardText,
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
            Text(label,
                style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w500,
                    color:      _cardText)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color:        AppTheme.accentCream,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(display,
                  style: const TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                      color:      AppTheme.primaryBlue)),
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
  // SECTION 3 — Colour Themes
  // ════════════════════════════════════════════════════════════════════════════

  Widget _colorThemeSection() {
    return _sectionCard(
      title:       '🎨  Colour Themes',
      description: 'Pick a background and text colour combination proven to reduce eye strain.',
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          const spacing   = 8.0;
          final cardWidth = (constraints.maxWidth - spacing) / 2;
          const cardHeight = 195.0;

          // Group into primary + premium sections.
          const primaryKeys = [
            'cream_black', 'soft_yellow_black', 'pale_blue_navy',
            'pale_green_gray', 'peach_black', 'white_black', 'dark_mode',
          ];
          const premiumKeys = [
            'cream_navy', 'cream_dark_green',
            'cream_burgundy', 'soft_yellow_purple',
          ];

          Widget themeGrid(List<String> keys) => Wrap(
            spacing:    spacing,
            runSpacing: spacing,
            children:   keys
                .map((k) => SizedBox(
                      width:  cardWidth,
                      height: cardHeight,
                      child:  _themeCard(k),
                    ))
                .toList(),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              themeGrid(primaryKeys),
              const SizedBox(height: AppTheme.spaceMD),
              // Premium themes divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Premium Themes',
                      style: TextStyle(
                        fontSize:   11,
                        fontWeight: FontWeight.w700,
                        color:      _cardText.withOpacity(0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSM),
              themeGrid(premiumKeys),
            ],
          );
        },
      ),
    );
  }

  Widget _themeCard(String key) {
    final active    = _pendingTheme == key;
    final isApplied = UIAccessibility.activeColorTheme == key;
    final bg        = UIAccessibility.themeBg(key);
    final tc        = UIAccessibility.themeText(key);
    final label     = UIAccessibility.colorThemeLabels[key] ?? key;
    final desc      = UIAccessibility.colorThemeDescriptions[key] ?? '';
    final badge     = UIAccessibility.colorThemeBadges[key];

    return GestureDetector(
      onTap: () => _preview(() {
        _pendingTheme     = key;
        _pendingTextColor = tc;
        _pendingBgColor   = bg;
        _pendingProfile   = 'custom';
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: active ? AppTheme.primaryBlue : Colors.grey.shade300,
            width: active ? 2.5 : 1,
          ),
          boxShadow: active
              ? [BoxShadow(
                  color:      AppTheme.primaryBlue.withOpacity(0.2),
                  blurRadius: 8,
                  offset:     const Offset(0, 3),
                )]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge (Most Popular / High Contrast)
            if (badge != null) ...[
              _badgePill(badge),
              const SizedBox(height: 5),
            ] else
              const SizedBox(height: 2),

            // Mini app preview — rendered in the theme's own colours
            Expanded(
              child: Container(
                width:   double.infinity,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color:        bg,
                  borderRadius: BorderRadius.circular(6),
                  border:       Border.all(
                    color: tc.withOpacity(0.15),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'AksharAlly',
                      style: TextStyle(
                        fontFamily: 'OpenDyslexic',
                        fontSize:   8.5,
                        fontWeight: FontWeight.bold,
                        color:      tc,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    _miniRow(Icons.book_outlined,         'Continue Reading', tc),
                    _miniRow(Icons.auto_stories_outlined, 'Library',          tc),
                    _miniRow(Icons.settings_outlined,     'Settings',         tc),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Theme name
            Text(
              label,
              style: TextStyle(
                fontSize:   10.5,
                fontWeight: FontWeight.w700,
                color:      _cardText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Description
            Text(
              desc,
              style: TextStyle(
                fontSize: 9,
                color:    _cardText.withOpacity(0.55),
                height:   1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Selection indicator
            if (active || isApplied) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 10, color: AppTheme.primaryBlue),
                  const SizedBox(width: 3),
                  Text(
                    isApplied ? 'Applied' : 'Selected',
                    style: const TextStyle(
                      fontSize:   9,
                      fontWeight: FontWeight.w600,
                      color:      AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Icon(icon, size: 7, color: color.withOpacity(0.65)),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 7,
                color:    color.withOpacity(0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SECTION 4 — Custom Appearance
  // ════════════════════════════════════════════════════════════════════════════

  Widget _customAppearanceSection() {
    return _sectionCard(
      title:       '✏️  Custom Appearance',
      description: 'Override colours manually for a fully personalised look.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Text Colour',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize:   13,
                  color:      _cardText)),
          const SizedBox(height: AppTheme.spaceSM),
          _swatchRow(
            swatches: UIAccessibility.textSwatches,
            selected: _pendingTextColor,
            onSelect: (c) => _preview(() {
              _pendingTextColor = c;
              _pendingProfile   = 'custom';
              _pendingTheme     = 'custom';
            }),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Text('Background Colour',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize:   13,
                  color:      _cardText)),
          const SizedBox(height: AppTheme.spaceSM),
          _swatchRow(
            swatches: UIAccessibility.bgSwatches,
            selected: _pendingBgColor,
            onSelect: (c) => _preview(() {
              _pendingBgColor = c;
              _pendingProfile = 'custom';
              _pendingTheme   = 'custom';
            }),
          ),

          // ── Contrast warning — live, non-blocking ─────────────────────────
          _contrastWarning(),
        ],
      ),
    );
  }

  /// Warns when the pending text/background combination has a WCAG contrast
  /// ratio below 4.5:1.  The warning is advisory — Apply is never blocked.
  Widget _contrastWarning() {
    final ratio = _contrastRatio(_pendingTextColor, _pendingBgColor);
    if (ratio >= 4.5) return const SizedBox.shrink();

    final String level;
    if (ratio < 2.0) {
      level = 'Very low (${ratio.toStringAsFixed(1)}:1)';
    } else {
      level = '${ratio.toStringAsFixed(1)}:1';
    }

    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spaceMD),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border:       Border.all(color: const Color(0xFFFFE082), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.warning_amber_rounded,
                size: 17, color: Color(0xFFE65100)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '⚠ Low contrast combination detected ($level).\n'
              'This may reduce readability.',
              style: const TextStyle(
                fontSize: 11,
                color:    Color(0xFF4E342E),
                height:   1.4,
              ),
            ),
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
      spacing:    AppTheme.spaceSM,
      runSpacing: AppTheme.spaceSM,
      children:   swatches.map((c) {
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
                    size:  16,
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
      title:       '♿  Accessibility Options',
      description: 'Further settings for visual comfort and motor accessibility.',
      child: Column(
        children: [
          _toggle(
            icon:      Icons.format_bold,
            label:     'Bold UI Text',
            value:     _pendingBold,
            onChanged: (v) => _preview(() => _pendingBold = v),
          ),
          _toggle(
            icon:      Icons.animation,
            label:     'Reduced Animations',
            value:     _pendingAnim,
            onChanged: (v) => _preview(() => _pendingAnim = v),
          ),
          _toggle(
            icon:      Icons.touch_app_outlined,
            label:     'Larger Touch Targets',
            value:     _pendingLargeTap,
            onChanged: (v) => _preview(() => _pendingLargeTap = v),
          ),
          _toggle(
            icon:      Icons.contrast,
            label:     'High Contrast Mode',
            value:     _pendingContrast,
            onChanged: (v) => _preview(() => _pendingContrast = v),
          ),
          const Divider(height: AppTheme.spaceLG),
          // Language applies immediately — feeds AppSettings.language for OCR
          Row(
            children: [
              const Icon(Icons.language, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(
                child: Text('Language',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: _cardText)),
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
                side:  const BorderSide(color: AppTheme.primaryBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                // Apply dyslexia defaults immediately (no preview for Reset)
                UIAccessibility.reset();
                setState(() {
                  _pendingFont      = UIAccessibility.fontFamily;
                  _pendingSize      = UIAccessibility.fontSize;
                  _pendingLetterSp  = UIAccessibility.letterSpacing;
                  _pendingWordSp    = UIAccessibility.wordSpacing;
                  _pendingLineH     = UIAccessibility.lineHeight;
                  _pendingTextColor = UIAccessibility.textColor;
                  _pendingBgColor   = UIAccessibility.backgroundColor;
                  _pendingTheme     = UIAccessibility.activeColorTheme;
                  _pendingProfile   = UIAccessibility.activeProfile;
                  _pendingBold      = UIAccessibility.boldTextEnabled;
                  _pendingContrast  = UIAccessibility.highContrastEnabled;
                  _pendingAnim      = UIAccessibility.reducedAnimationsEnabled;
                  _pendingLargeTap  = UIAccessibility.largeTouchTargetsEnabled;
                  _hasPendingChanges = false;
                });
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
                  style: TextStyle(
                      fontWeight: FontWeight.w500, color: _cardText))),
          Switch(value: value, onChanged: onChanged),
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
  // SECTION 6 — Live Preview
  // ════════════════════════════════════════════════════════════════════════════

  Widget _livePreviewSection() {
    // Build TextStyle using PENDING values — preview updates immediately.
    TextStyle pts(double size, FontWeight w) {
      return UIAccessibility.previewStyleFor(_pendingFont).copyWith(
        fontSize:           size,
        fontWeight:         _pendingBold ? FontWeight.bold : w,
        color:              _pendingTextColor,
        letterSpacing:      _pendingLetterSp,
        wordSpacing:        _pendingWordSp,
        height:             _pendingLineH,
        fontFamilyFallback: const ['Noto Sans', 'sans-serif'],
      );
    }

    return _sectionCard(
      title: '👁️  Live Preview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reflects your current selections only. Press Apply Changes to update the app.',
            style: TextStyle(
                fontSize: 12,
                color:    _cardText.withOpacity(0.65),
                height:   1.4),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width:    double.infinity,
            padding:  const EdgeInsets.all(AppTheme.spaceMD),
            decoration: BoxDecoration(
              color:        _pendingBgColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border:       Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AksharAlly',
                    style:    pts(_pendingSize + 6, FontWeight.w900),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Welcome Back',
                    style:    pts(_pendingSize - 1, FontWeight.w500)
                        .copyWith(color: _pendingTextColor.withOpacity(0.7)),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                _previewRow(Icons.book_outlined,
                    'Continue Reading', pts(_pendingSize, FontWeight.w600)),
                _previewRow(Icons.add_circle_outline,
                    'New Reading',      pts(_pendingSize, FontWeight.w600)),
                _previewRow(Icons.auto_stories_outlined,
                    'Library',          pts(_pendingSize, FontWeight.w600)),
                _previewRow(Icons.settings_outlined,
                    'Settings',         pts(_pendingSize, FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Font: $_pendingFont  ·  Size: ${_pendingSize.toStringAsFixed(0)}'
                  '  ·  Theme: ${UIAccessibility.colorThemeLabels[_pendingTheme] ?? 'Custom'}',
                  style:    const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewRow(IconData icon, String label, TextStyle ts) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: _pendingTextColor.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: ts, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SECTION 7 — Reading History
  // ════════════════════════════════════════════════════════════════════════════

  Widget _readingHistorySection() {
    return _sectionCard(
      title: '📚  Reading History',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${LibraryStorage.getItems().length} saved readings',
            style: TextStyle(fontSize: 13, color: _cardText.withOpacity(0.7)),
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

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Screen header — colour is computed from background luminance so it
        // is always readable regardless of which theme is applied.
        Text(
          'Accessibility Center',
          style: TextStyle(
            fontSize:   20,
            fontWeight: FontWeight.w800,
            color:      _headerColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Customise how AksharAlly looks — preview changes before applying.',
          style: TextStyle(
            fontSize: 12,
            color:    _headerColor.withOpacity(0.75),
            height:   1.4,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMD),

        // Action banner — appears when preview differs from applied
        _actionBanner(),

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
