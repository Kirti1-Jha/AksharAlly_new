import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _tts = FlutterTts();

  bool isSpeaking = false;
  double _speechRate = 0.4;

  /// INIT
  Future<void> init() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    // Track speaking state
    _tts.setStartHandler(() {
      isSpeaking = true;
    });

    _tts.setCompletionHandler(() {
      isSpeaking = false;
    });

    _tts.setCancelHandler(() {
      isSpeaking = false;
    });

    _tts.setErrorHandler((msg) {
      isSpeaking = false;
      print("TTS Error: $msg");
    });
  }

  /// SET SPEED (NEW FEATURE)
  Future<void> setRate(double rate) async {
    _speechRate = rate;
    await _tts.setSpeechRate(rate);
  }

  /// GET CURRENT SPEED
  double get currentRate => _speechRate;

  /// SPEAK (USED FOR AUTO + MANUAL)
  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    await _tts.stop(); // stop previous speech
    await _tts.speak(text);
  }

  /// STOP
  Future<void> stop() async {
    await _tts.stop();
    isSpeaking = false;
  }
}