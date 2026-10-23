import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static double fontSize = 18;
  static double lineSpacing = 1.5;
  static int themeMode = 0;
  static String language = 'en'; // 'en' = English | 'hi' = Hindi
  static String interfaceLanguage = 'en';
  static bool voiceAssistanceEnabled = false;
  static String voiceLanguage = 'en';
  static String voiceLocaleId = 'en-IN';
  static double speechRate = 0.4;
  static bool readingHighlight = true;
  static bool autoSimplifyText = false;

  static const _voiceAssistanceKey = 'aksharally.voice-assistance.v1';
  static const _voiceLanguageKey = 'aksharally.voice-language.v1';
  static const _voiceLocaleKey = 'aksharally.voice-locale.v1';
  static const _interfaceLanguageKey = 'aksharally.interface-language.v1';

  static Future<void> loadInterfaceLanguagePreference() async {
    final preferences = await SharedPreferences.getInstance();
    final savedLanguage = preferences.getString(_interfaceLanguageKey);
    if (savedLanguage == 'en' || savedLanguage == 'hi') {
      interfaceLanguage = savedLanguage!;
    }
  }

  static Future<void> saveInterfaceLanguagePreference(String language) async {
    if (language != 'en' && language != 'hi') {
      throw ArgumentError.value(language, 'language', 'Expected en or hi.');
    }
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_interfaceLanguageKey, language);
    if (!saved) {
      throw StateError('Could not persist interface language.');
    }
    interfaceLanguage = language;
  }

  static Future<void> loadVoiceAssistancePreference() async {
    final preferences = await SharedPreferences.getInstance();
    voiceAssistanceEnabled =
        preferences.getBool(_voiceAssistanceKey) ?? voiceAssistanceEnabled;
    voiceLanguage = preferences.getString(_voiceLanguageKey) ?? voiceLanguage;
    voiceLocaleId = preferences.getString(_voiceLocaleKey) ?? voiceLocaleId;
  }

  static Future<void> saveVoiceAssistancePreference(bool enabled) async {
    voiceAssistanceEnabled = enabled;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_voiceAssistanceKey, enabled);
  }

  static Future<void> saveVoiceLanguagePreference(
    String language, {
    String? localeId,
  }) async {
    voiceLanguage = language;
    if (localeId != null) voiceLocaleId = localeId;
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString(_voiceLanguageKey, language),
      if (localeId != null) preferences.setString(_voiceLocaleKey, localeId),
    ]);
  }
}
