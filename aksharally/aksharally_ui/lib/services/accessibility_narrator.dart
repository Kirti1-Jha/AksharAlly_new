import 'package:flutter/foundation.dart';

import '../theme/app_settings.dart';
import 'tts_service.dart';

/// Speaks short interface instructions using the selected interface language.
///
/// This deliberately does not read or modify the content-reading or
/// voice-command language preferences.
class AccessibilityNarrator {
  AccessibilityNarrator(this._tts);

  final TTSService _tts;
  int _request = 0;

  Future<void> speak(
    String text, {
    Future<void> Function()? interrupt,
  }) async {
    if (text.trim().isEmpty) return;
    final request = ++_request;
    bool isCurrent() => request == _request;

    try {
      if (interrupt != null) {
        await interrupt();
      } else {
        await _tts.stop();
      }
      if (!isCurrent()) return;

      await _tts.init(defaultLocale: null);
      if (!isCurrent()) return;

      final locale = TTSService.localeForLanguage(
        AppSettings.interfaceLanguage,
      );
      if (locale == null) {
        await _tts.resetVoiceToDefault();
      } else {
        final selected = await _tts.setLanguage(locale);
        if (!isCurrent()) return;
        if (!selected) await _tts.resetVoiceToDefault();
      }
      if (!isCurrent()) return;

      await _tts.speak(text);
    } catch (error) {
      debugPrint('Accessibility narration unavailable: $error');
    }
  }

  Future<void> cancel({Future<void> Function()? interrupt}) async {
    ++_request;
    try {
      if (interrupt != null) {
        await interrupt();
      } else {
        await _tts.stop();
      }
    } catch (error) {
      debugPrint('Could not stop accessibility narration: $error');
    }
  }
}
