import 'package:shared_preferences/shared_preferences.dart';

/// Global accessibility settings for the app.
///
/// All fields are plain static variables so any screen can read them
/// synchronously after the initial [load] call in main.dart.
///
/// Call [load] once at startup (before runApp) to restore saved values.
/// Call [save] after any field changes to write them to disk.
class AppSettings {
  // ── Storage keys ─────────────────────────────────────────────────────────
  static const _kFontSize       = 'font_size';
  static const _kLineSpacing    = 'line_spacing';
  static const _kThemeMode      = 'theme_mode';
  static const _kReadingProfile = 'reading_profile';

  // ── Live values (read by UI synchronously) ───────────────────────────────
  static double fontSize       = 18;
  static double lineSpacing    = 1.5;
  static int    themeMode      = 0;

  /// The user's chosen dyslexia reading profile.
  /// One of: "mild" | "moderate" | "severe".
  /// Defaults to "moderate" on first install.
  static String readingProfile = 'moderate';

  // ── Persistence ──────────────────────────────────────────────────────────

  /// Restores all settings from SharedPreferences.
  ///
  /// Must be awaited once in [main] before [runApp] so that every screen
  /// sees the correct values on the very first build.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    fontSize       = prefs.getDouble(_kFontSize)       ?? 18;
    lineSpacing    = prefs.getDouble(_kLineSpacing)     ?? 1.5;
    themeMode      = prefs.getInt(_kThemeMode)          ?? 0;
    readingProfile = prefs.getString(_kReadingProfile)  ?? 'moderate';
  }

  /// Writes all current settings to SharedPreferences.
  ///
  /// Call this after changing any field so the value survives a restart.
  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(_kFontSize,    fontSize);
    await prefs.setDouble(_kLineSpacing, lineSpacing);
    await prefs.setInt(_kThemeMode,      themeMode);
    await prefs.setString(_kReadingProfile, readingProfile);
  }
}
