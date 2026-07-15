import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Client-side accessibility preferences for the ReaderScreen.
///
/// This class is intentionally separate from [FormatResult] (backend response)
/// and [AppSettings] (global app prefs). It owns only reading-presentation
/// concerns: font, spacing, colors, and accessibility toggles.
///
/// Call [load] once in main() before runApp.
/// Call [save] whenever the user confirms a change.
/// Call [applyPreset] when the user picks mild / moderate / severe.
class AccessibilitySettings {
  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const _kProfile     = 'a11y_profile';
  static const _kFont        = 'a11y_font';
  static const _kFontSize    = 'a11y_fontSize';
  static const _kLetterSp    = 'a11y_letterSpacing';
  static const _kWordSp      = 'a11y_wordSpacing';
  static const _kLineH       = 'a11y_lineHeight';
  static const _kParaSp      = 'a11y_paragraphSpacing';
  static const _kColorTheme  = 'a11y_colorTheme';
  static const _kWordHL      = 'a11y_wordHighlighting';
  static const _kFocusLine   = 'a11y_focusLineMode';
  static const _kRuler       = 'a11y_readingRuler';
  static const _kSyllable    = 'a11y_syllableBreakdown';
  static const _kLargerTap   = 'a11y_largerTouchTargets';
  static const _kReduceMot   = 'a11y_reduceMotion';

  // ── Live values (read synchronously after load) ───────────────────────────

  static String profile          = 'moderate';   // 'mild'|'moderate'|'severe'|'customize'
  static String fontFamily       = 'Lexend';
  static double fontSize         = 22.0;
  static double letterSpacing    = 1.0;
  static double wordSpacing      = 4.0;
  static double lineHeight       = 1.8;
  static double paragraphSpacing = 16.0;
  static String colorTheme       = 'soft_yellow_brown';

  // Accessibility feature toggles
  static bool wordHighlighting   = true;
  static bool focusLineMode      = false;
  static bool readingRuler       = false;
  static bool syllableBreakdown  = false;
  static bool largerTouchTargets = false;
  static bool reduceMotion       = false;

  // ── Presets ───────────────────────────────────────────────────────────────

  /// Applies a built-in preset.  Calling with 'customize' is a no-op —
  /// the user's existing custom values are preserved.
  static void applyPreset(String p) {
    profile = p;
    switch (p) {
      case 'mild':
        fontFamily       = 'Lexend';
        fontSize         = 18.0;
        letterSpacing    = 0.5;
        wordSpacing      = 2.0;
        lineHeight       = 1.5;
        paragraphSpacing = 12.0;
        colorTheme       = 'cream_dark_gray';
        break;
      case 'moderate':
        fontFamily       = 'Lexend';
        fontSize         = 22.0;
        letterSpacing    = 1.0;
        wordSpacing      = 4.0;
        lineHeight       = 1.8;
        paragraphSpacing = 16.0;
        colorTheme       = 'soft_yellow_brown';
        break;
      case 'severe':
        fontFamily       = 'Lexend';
        fontSize         = 26.0;
        letterSpacing    = 1.5;
        wordSpacing      = 6.0;
        lineHeight       = 2.2;
        paragraphSpacing = 24.0;
        colorTheme       = 'soft_blue_navy';
        break;
      // 'customize': leave all values as-is — user controls them.
    }
  }

  // ── Font families available in the Customize panel ────────────────────────

  static const List<String> fonts = [
    'OpenDyslexic',           // Maps to Lexend (not in Google Fonts; graceful fallback)
    'Lexend',
    'Atkinson Hyperlegible',  // GoogleFonts.atkinsonHyperlegible
    'Noto Sans',              // GoogleFonts.notoSans
    'System Default',         // Plain TextStyle, no Google Font
  ];

  // ── Color themes ──────────────────────────────────────────────────────────

  /// Human-readable label for each theme key.
  static const Map<String, String> themeLabels = {
    'cream_dark_gray':    'Cream',
    'soft_yellow_brown':  'Soft Yellow',
    'soft_blue_navy':     'Soft Blue',
    'mint_dark_gray':     'Mint Green',
    'lavender_dark_gray': 'Lavender',
    'dark_mode':          'Dark Mode',
    'high_contrast':      'High Contrast',
  };

  /// Background color for a given theme key — safe to call with any key.
  static Color previewBg(String key) {
    switch (key) {
      case 'cream_dark_gray':    return const Color(0xFFFDF6E3);
      case 'soft_yellow_brown':  return const Color(0xFFFFF9C4);
      case 'soft_blue_navy':     return const Color(0xFFE3F2FD);
      case 'mint_dark_gray':     return const Color(0xFFE8F5E9);
      case 'lavender_dark_gray': return const Color(0xFFF3E5F5);
      case 'dark_mode':          return const Color(0xFF1E1E1E);
      case 'high_contrast':      return const Color(0xFF000000);
      default:                   return const Color(0xFFFFF9C4);
    }
  }

  /// Text color for a given theme key — safe to call with any key.
  static Color previewText(String key) {
    switch (key) {
      case 'cream_dark_gray':    return const Color(0xFF333333);
      case 'soft_yellow_brown':  return const Color(0xFF4A3728);
      case 'soft_blue_navy':     return const Color(0xFF1A237E);
      case 'mint_dark_gray':     return const Color(0xFF333333);
      case 'lavender_dark_gray': return const Color(0xFF333333);
      case 'dark_mode':          return const Color(0xFFE0E0E0);
      case 'high_contrast':      return const Color(0xFFFFFF00);
      default:                   return const Color(0xFF4A3728);
    }
  }

  /// Background color for the currently active theme.
  static Color backgroundColor() => previewBg(colorTheme);

  /// Text color for the currently active theme.
  static Color textColor() => previewText(colorTheme);

  // ── Persistence ───────────────────────────────────────────────────────────

  /// Restore all settings from SharedPreferences.
  /// Call once in main() before runApp, after WidgetsFlutterBinding.ensureInitialized.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_kProfile) == null) {
      // First launch — apply moderate preset and return.
      applyPreset('moderate');
      return;
    }
    profile          = prefs.getString(_kProfile)    ?? 'moderate';
    fontFamily       = prefs.getString(_kFont)       ?? 'Lexend';
    fontSize         = prefs.getDouble(_kFontSize)   ?? 22.0;
    letterSpacing    = prefs.getDouble(_kLetterSp)   ?? 1.0;
    wordSpacing      = prefs.getDouble(_kWordSp)     ?? 4.0;
    lineHeight       = prefs.getDouble(_kLineH)      ?? 1.8;
    paragraphSpacing = prefs.getDouble(_kParaSp)     ?? 16.0;
    colorTheme       = prefs.getString(_kColorTheme) ?? 'soft_yellow_brown';
    wordHighlighting   = prefs.getBool(_kWordHL)     ?? true;
    focusLineMode      = prefs.getBool(_kFocusLine)  ?? false;
    readingRuler       = prefs.getBool(_kRuler)      ?? false;
    syllableBreakdown  = prefs.getBool(_kSyllable)   ?? false;
    largerTouchTargets = prefs.getBool(_kLargerTap)  ?? false;
    reduceMotion       = prefs.getBool(_kReduceMot)  ?? false;
  }

  /// Write all current settings to SharedPreferences.
  /// Call after every preset change or after the user confirms custom values.
  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_kProfile,    profile),
      prefs.setString(_kFont,       fontFamily),
      prefs.setDouble(_kFontSize,   fontSize),
      prefs.setDouble(_kLetterSp,   letterSpacing),
      prefs.setDouble(_kWordSp,     wordSpacing),
      prefs.setDouble(_kLineH,      lineHeight),
      prefs.setDouble(_kParaSp,     paragraphSpacing),
      prefs.setString(_kColorTheme, colorTheme),
      prefs.setBool(_kWordHL,       wordHighlighting),
      prefs.setBool(_kFocusLine,    focusLineMode),
      prefs.setBool(_kRuler,        readingRuler),
      prefs.setBool(_kSyllable,     syllableBreakdown),
      prefs.setBool(_kLargerTap,    largerTouchTargets),
      prefs.setBool(_kReduceMot,    reduceMotion),
    ]);
  }
}
