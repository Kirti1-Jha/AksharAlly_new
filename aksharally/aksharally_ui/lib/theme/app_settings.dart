import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static double fontSize   = 18;
  static double lineSpacing = 1.5;
  static int    themeMode  = 0;
  static String language   = 'en';   // 'en' = English | 'hi' = Hindi
  static String interfaceLanguage = 'en';
  static bool voiceAssistanceEnabled = false;
  static String voiceLanguage = 'en';
  static double speechRate = 0.4;
  static bool readingHighlight = true;
  static bool autoSimplifyText = false;

  static const _voiceAssistanceKey = 'aksharally.voice-assistance.v1';

  static Future<void> loadVoiceAssistancePreference() async {
    final preferences = await SharedPreferences.getInstance();
    voiceAssistanceEnabled =
        preferences.getBool(_voiceAssistanceKey) ?? voiceAssistanceEnabled;
  }

  static Future<void> saveVoiceAssistancePreference(bool enabled) async {
    voiceAssistanceEnabled = enabled;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_voiceAssistanceKey, enabled);
  }
}
