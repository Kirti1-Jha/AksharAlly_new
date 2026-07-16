import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UI-layer accessibility settings for AksharAlly.
///
/// Controls how the application interface looks (headings, cards, nav labels,
/// buttons, home screen text, etc.).  It has NO effect on reader content —
/// OCR output, PDF text, simplified text, and OutputScreen rendering remain
/// governed by [AccessibilitySettings].
///
/// Call [load] once in main() before runApp.
/// Call [change] to mutate any field — it persists and fires [notifier].
/// Wrap MaterialApp in ValueListenableBuilder<int>(valueListenable:
/// UIAccessibility.notifier) and pass [buildTheme()] as the theme to get
/// instant global propagation without Provider or ChangeNotifier.
class UIAccessibility {
  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const _kInit         = 'ui_a11y_initialized';
  static const _kProfile      = 'ui_a11y_profile';
  static const _kFont         = 'ui_a11y_font';
  static const _kFontSize     = 'ui_a11y_fontSize';
  static const _kLetterSp     = 'ui_a11y_letterSpacing';
  static const _kWordSp       = 'ui_a11y_wordSpacing';
  static const _kLineH        = 'ui_a11y_lineHeight';
  static const _kColorTheme   = 'ui_a11y_colorTheme';
  static const _kTextColor    = 'ui_a11y_textColor';
  static const _kBgColor      = 'ui_a11y_bgColor';
  static const _kBoldText     = 'ui_a11y_boldText';
  static const _kHighContrast = 'ui_a11y_highContrast';
  static const _kReduceAnim   = 'ui_a11y_reduceAnim';
  static const _kLargeTargets = 'ui_a11y_largeTargets';

  // ── Live values ───────────────────────────────────────────────────────────

  static String activeProfile   = 'dyslexia';
  static String fontFamily      = 'OpenDyslexic'; // default for first-time users
  static double fontSize        = 15.0;
  static double letterSpacing   = 0.3;
  static double wordSpacing     = 2.0;
  static double lineHeight      = 1.6;
  static String activeColorTheme = 'cream';
  static Color  textColor       = const Color(0xFF333333);
  static Color  backgroundColor = const Color(0xFFFDF6E3);

  static bool boldTextEnabled           = false;
  static bool highContrastEnabled       = false;
  static bool reducedAnimationsEnabled  = false;
  static bool largeTouchTargetsEnabled  = false;

  // ── Global rebuild notifier ────────────────────────────────────────────────
  /// Increment this to force AksharAllyApp to rebuild MaterialApp with the
  /// new ThemeData — no Provider or ChangeNotifier needed.
  static final ValueNotifier<int> notifier = ValueNotifier(0);

  // ── Font catalogue ─────────────────────────────────────────────────────────

  static const List<String> fonts = [
    'OpenDyslexic',          // bundled asset — primary dyslexia font
    'Lexend',                // Google Fonts
    'Atkinson Hyperlegible', // Google Fonts
    'Inter',                 // Google Fonts
    'Roboto',                // Google Fonts / system
    'Monospace',             // Roboto Mono via Google Fonts
  ];

  // ── Profiles ───────────────────────────────────────────────────────────────

  static const Map<String, String> profileLabels = {
    'dyslexia':   'Dyslexia Recommended',
    'eye_strain': 'Low Eye Strain',
    'clarity':    'Maximum Clarity',
    'beginner':   'Beginner Reader',
  };

  static const Map<String, String> profileDescriptions = {
    'dyslexia':   'OpenDyslexic · Cream · Generous spacing',
    'eye_strain': 'Inter · Soft Yellow · Reduced glare',
    'clarity':    'Monospace · White · Large, spaced text',
    'beginner':   'OpenDyslexic · Light Blue · Very large text',
  };

  /// Applies all fields for the given profile key.
  static void applyProfile(String key) {
    activeProfile = key;
    switch (key) {
      case 'dyslexia':
        fontFamily      = 'OpenDyslexic';
        fontSize        = 15.0;
        letterSpacing   = 0.3;
        wordSpacing     = 2.0;
        lineHeight      = 1.6;
        activeColorTheme = 'cream';
        textColor       = const Color(0xFF333333);
        backgroundColor = const Color(0xFFFDF6E3);
        break;
      case 'eye_strain':
        fontFamily      = 'Inter';
        fontSize        = 14.0;
        letterSpacing   = 0.2;
        wordSpacing     = 1.5;
        lineHeight      = 1.5;
        activeColorTheme = 'soft_yellow';
        textColor       = const Color(0xFF4A3728);
        backgroundColor = const Color(0xFFFFF9C4);
        break;
      case 'clarity':
        fontFamily      = 'Monospace';
        fontSize        = 16.0;
        letterSpacing   = 0.5;
        wordSpacing     = 3.0;
        lineHeight      = 1.8;
        activeColorTheme = 'white';
        textColor       = const Color(0xFF000000);
        backgroundColor = const Color(0xFFFFFFFF);
        break;
      case 'beginner':
        fontFamily      = 'OpenDyslexic';
        fontSize        = 18.0;
        letterSpacing   = 0.5;
        wordSpacing     = 4.0;
        lineHeight      = 2.0;
        activeColorTheme = 'light_blue';
        textColor       = const Color(0xFF1A237E);
        backgroundColor = const Color(0xFFE3F2FD);
        break;
    }
  }

  // ── Color themes ───────────────────────────────────────────────────────────

  static const Map<String, String> colorThemeLabels = {
    'cream':       'Cream',
    'soft_yellow': 'Soft Yellow',
    'light_blue':  'Light Blue',
    'pale_green':  'Pale Green',
    'peach':       'Peach',
    'white':       'Clean White',
  };

  static Color themeBg(String key) {
    switch (key) {
      case 'cream':       return const Color(0xFFFDF6E3);
      case 'soft_yellow': return const Color(0xFFFFF9C4);
      case 'light_blue':  return const Color(0xFFE3F2FD);
      case 'pale_green':  return const Color(0xFFE8F5E9);
      case 'peach':       return const Color(0xFFFFE0CC);
      case 'white':       return const Color(0xFFFFFFFF);
      default:            return const Color(0xFFFDF6E3);
    }
  }

  static Color themeText(String key) {
    switch (key) {
      case 'cream':       return const Color(0xFF333333);
      case 'soft_yellow': return const Color(0xFF4A3728);
      case 'light_blue':  return const Color(0xFF1A237E);
      case 'pale_green':  return const Color(0xFF2E5B2E);
      case 'peach':       return const Color(0xFF3E1F00);
      case 'white':       return const Color(0xFF000000);
      default:            return const Color(0xFF333333);
    }
  }

  // ── Custom appearance swatches ─────────────────────────────────────────────

  static const List<Color> textSwatches = [
    Color(0xFF1A1A1A), Color(0xFF333333), Color(0xFF4A3728),
    Color(0xFF1A237E), Color(0xFF2E5B2E), Color(0xFF880E4F),
    Color(0xFF000000), Color(0xFFFFFFFF),
  ];

  static const List<Color> bgSwatches = [
    Color(0xFFFDF6E3), Color(0xFFFFF9C4), Color(0xFFE3F2FD),
    Color(0xFFE8F5E9), Color(0xFFFFE0CC), Color(0xFFF3E5F5),
    Color(0xFFFFFFFF), Color(0xFF1E1E1E),
  ];

  // ── Theme builder ──────────────────────────────────────────────────────────

  /// Builds a complete ThemeData from the current settings.
  /// Pass this to MaterialApp(theme: ...) inside a ValueListenableBuilder.
  static ThemeData buildTheme() {
    const primary       = Color(0xFF1565C0);
    const primaryLight  = Color(0xFF42A5F5);
    const primaryGreen  = Color(0xFF4CAF93);
    const errorColor    = Color(0xFFD32F2F);
    const muted         = Color(0xFF757575);

    final double btnHeight = largeTouchTargetsEnabled ? 60.0 : 52.0;

    return ThemeData(
      useMaterial3: false,
      scaffoldBackgroundColor: backgroundColor,

      colorScheme: ColorScheme.light(
        primary:   primary,
        secondary: primaryGreen,
        surface:   backgroundColor,
        error:     errorColor,
      ),

      textTheme: TextTheme(
        displayLarge:   _ts(fontSize + 18, FontWeight.w900,  textColor),
        headlineMedium: _ts(fontSize + 10, FontWeight.bold,  textColor),
        titleMedium:    _ts(fontSize + 2,  FontWeight.w700,  textColor),
        labelMedium:    _ts(fontSize - 2,  FontWeight.w600,  textColor),
        bodyMedium:     _ts(fontSize,      FontWeight.w400,  textColor),
        bodySmall:      _ts(fontSize - 3,  FontWeight.w400,  muted),
      ),

      appBarTheme: AppBarTheme(
        elevation:        0,
        backgroundColor:  Colors.transparent,
        foregroundColor:  primary,
        centerTitle:      true,
        titleTextStyle:   _ts(fontSize + 4, FontWeight.w800, primary),
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize:     Size(double.infinity, btnHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: _ts(fontSize, FontWeight.w600, Colors.white),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, btnHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: _ts(fontSize, FontWeight.w600, primary),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide:   BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide:   BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide:   const BorderSide(color: primary, width: 2),
        ),
        hintStyle: const TextStyle(color: muted),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor:   primary,
        inactiveTrackColor: primary.withOpacity(0.2),
        thumbColor:         primary,
        overlayColor:       primary.withOpacity(0.1),
        trackHeight:        4,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? primaryGreen
              : const Color(0xFFBDBDBD),
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? primaryGreen.withOpacity(0.4)
              : const Color(0xFFE0E0E0),
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        behavior:         SnackBarBehavior.floating,
        backgroundColor:  Color(0xFF323232),
        contentTextStyle: TextStyle(color: Colors.white),
      ),

      dividerTheme: const DividerThemeData(
        color:     Color(0xFFE0E0E0),
        thickness: 1,
        space:     1,
      ),

      // Gradients (stored here for convenience — accessed as
      // Theme.of(context).extension<...>() in future if needed).
      extensions: const [],
    );
  }

  // ── TextStyle factory ──────────────────────────────────────────────────────

  /// Returns a TextStyle for [fontFamily] with Noto Sans as the Devanagari
  /// (Hindi/Marathi) fallback.  OpenDyslexic does not include Devanagari
  /// glyphs; Flutter will automatically pick the next matching fallback.
  static TextStyle _ts(double size, FontWeight weight, Color color) {
    final base = TextStyle(
      fontSize:           size,
      fontWeight:         boldTextEnabled ? FontWeight.bold : weight,
      color:              highContrastEnabled ? _highContrastColor(color) : color,
      letterSpacing:      letterSpacing,
      wordSpacing:        wordSpacing,
      height:             lineHeight,
      // Noto Sans covers Devanagari; system sans-serif is the last resort.
      fontFamilyFallback: const ['Noto Sans', 'sans-serif'],
    );

    if (fontFamily == 'OpenDyslexic') {
      return base.copyWith(fontFamily: 'OpenDyslexic');
    }

    final gfName = _gfName(fontFamily);
    try {
      return GoogleFonts.getFont(gfName, textStyle: base);
    } catch (_) {
      return base.copyWith(fontFamily: fontFamily);
    }
  }

  static Color _highContrastColor(Color c) {
    // In high-contrast mode snap all dark colours to pure black and
    // all light colours to pure white for maximum legibility.
    final lum = c.computeLuminance();
    if (lum < 0.3) return const Color(0xFF000000);
    if (lum > 0.7) return const Color(0xFFFFFFFF);
    return c;
  }

  static String _gfName(String name) {
    switch (name) {
      case 'Lexend':                return 'Lexend';
      case 'Atkinson Hyperlegible': return 'Atkinson Hyperlegible';
      case 'Inter':                 return 'Inter';
      case 'Roboto':                return 'Roboto';
      case 'Monospace':             return 'Roboto Mono';
      default:                      return 'Lexend';
    }
  }

  /// Returns a TextStyle for explicit font previews (font-chip row).
  /// Used by the settings screen to render each font name in its own face.
  static TextStyle previewStyleFor(String name) {
    const base = TextStyle(fontSize: 13, color: Color(0xFF333333));
    if (name == 'OpenDyslexic') return base.copyWith(fontFamily: 'OpenDyslexic');
    try {
      return GoogleFonts.getFont(_gfName(name), textStyle: base);
    } catch (_) {
      return base;
    }
  }

  // ── Mutate helper ──────────────────────────────────────────────────────────

  /// Apply a mutation, increment the notifier, and persist.
  /// Call from any widget that changes a setting.
  static void change(void Function() mutate) {
    mutate();
    notifier.value++;
    save(); // fire-and-forget
  }

  // ── Reset ──────────────────────────────────────────────────────────────────

  static void reset() {
    boldTextEnabled          = false;
    highContrastEnabled      = false;
    reducedAnimationsEnabled = false;
    largeTouchTargetsEnabled = false;
    applyProfile('dyslexia');
    notifier.value++;
    save();
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  /// Hydrate from SharedPreferences.  Call once in main() before runApp.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey(_kInit)) {
      // First launch — apply dyslexia defaults and persist so next launch
      // restores exactly these values (existing users keep their saved font).
      applyProfile('dyslexia');
      await save();
      return;
    }

    activeProfile          = prefs.getString(_kProfile)    ?? 'dyslexia';
    fontFamily             = prefs.getString(_kFont)       ?? 'OpenDyslexic';
    fontSize               = prefs.getDouble(_kFontSize)   ?? 15.0;
    letterSpacing          = prefs.getDouble(_kLetterSp)   ?? 0.3;
    wordSpacing            = prefs.getDouble(_kWordSp)     ?? 2.0;
    lineHeight             = prefs.getDouble(_kLineH)      ?? 1.6;
    activeColorTheme       = prefs.getString(_kColorTheme) ?? 'cream';
    textColor              = Color(prefs.getInt(_kTextColor)  ?? 0xFF333333);
    backgroundColor        = Color(prefs.getInt(_kBgColor)   ?? 0xFFFDF6E3);
    boldTextEnabled         = prefs.getBool(_kBoldText)     ?? false;
    highContrastEnabled     = prefs.getBool(_kHighContrast) ?? false;
    reducedAnimationsEnabled = prefs.getBool(_kReduceAnim)  ?? false;
    largeTouchTargetsEnabled = prefs.getBool(_kLargeTargets) ?? false;
  }

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(_kInit,          true),
      prefs.setString(_kProfile,     activeProfile),
      prefs.setString(_kFont,        fontFamily),
      prefs.setDouble(_kFontSize,    fontSize),
      prefs.setDouble(_kLetterSp,    letterSpacing),
      prefs.setDouble(_kWordSp,      wordSpacing),
      prefs.setDouble(_kLineH,       lineHeight),
      prefs.setString(_kColorTheme,  activeColorTheme),
      prefs.setInt(_kTextColor,      textColor.value),
      prefs.setInt(_kBgColor,        backgroundColor.value),
      prefs.setBool(_kBoldText,      boldTextEnabled),
      prefs.setBool(_kHighContrast,  highContrastEnabled),
      prefs.setBool(_kReduceAnim,    reducedAnimationsEnabled),
      prefs.setBool(_kLargeTargets,  largeTouchTargetsEnabled),
    ]);
  }
}
