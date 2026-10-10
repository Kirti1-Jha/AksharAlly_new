import 'package:flutter_tts/flutter_tts.dart';

typedef TTSProgressCallback =
    void Function(String text, int start, int end, String word);

class TTSService {
  final FlutterTts _tts = FlutterTts();

  bool isSpeaking = false;
  bool isPaused = false;
  double _speechRate = 0.4;
  String? _lastSpokenText;
  int _resumeOffset = 0;
  int _lastProgressEnd = 0;
  TTSProgressCallback? _progressCallback;
  void Function()? _completionCallback;
  String? lastError;

  /// Configure platform TTS handlers once for this reader session.
  Future<void> init() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    // Track speaking state
    _tts.setStartHandler(() {
      isSpeaking = true;
      isPaused = false;
    });

    _tts.setCompletionHandler(() {
      isSpeaking = false;
      isPaused = false;
      _completionCallback?.call();
    });

    _tts.setCancelHandler(() {
      isSpeaking = false;
      isPaused = false;
    });

    _tts.setPauseHandler(() {
      isSpeaking = false;
      isPaused = true;
    });

    _tts.setContinueHandler(() {
      isSpeaking = true;
      isPaused = false;
    });

    _tts.setProgressHandler((text, start, end, word) {
      final offset = _resumeOffset > 0 && start < _resumeOffset
          ? _resumeOffset
          : 0;
      final normalizedStart = start + offset;
      final normalizedEnd = end + offset;
      _lastProgressEnd = normalizedEnd;
      _progressCallback?.call(
        _lastSpokenText ?? text,
        normalizedStart,
        normalizedEnd,
        word,
      );
    });

    _tts.setErrorHandler((msg) {
      isSpeaking = false;
      isPaused = false;
      lastError = msg.toString();
    });
  }

  Future<void> setRate(double rate) async {
    _speechRate = rate;
    await _tts.setSpeechRate(rate);
  }

  double get currentRate => _speechRate;

  /// Changes the output voice only if the device reports that locale as usable.
  Future<bool> setLanguage(String localeId) async {
    final locale = localeId.replaceAll('_', '-');
    try {
      final available = await _tts.isLanguageAvailable(locale);
      if (available != true) return false;
      await _tts.setLanguage(locale);
      return true;
    } catch (error) {
      lastError = error.toString();
      return false;
    }
  }

  Future<void> speak(
    String text, {
    TTSProgressCallback? onProgress,
    void Function()? onComplete,
  }) async {
    if (text.isEmpty) return;

    await _tts.stop();
    _lastSpokenText = text;
    _resumeOffset = 0;
    _lastProgressEnd = 0;
    _progressCallback = onProgress;
    _completionCallback = onComplete;
    lastError = null;
    isPaused = false;
    await _tts.speak(text);
  }

  Future<bool> pause() async {
    if (isPaused) return true;
    if (!isSpeaking) return false;
    try {
      await _tts.pause();
      _resumeOffset = _lastProgressEnd;
      isSpeaking = false;
      isPaused = true;
      return true;
    } catch (error) {
      lastError = error.toString();
      return false;
    }
  }

  /// FlutterTts resumes its paused utterance when speak is called again.
  Future<bool> resume() async {
    final text = _lastSpokenText;
    if (!isPaused || text == null || text.isEmpty) return false;
    try {
      await _tts.speak(text);
      isPaused = false;
      isSpeaking = true;
      return true;
    } catch (error) {
      lastError = error.toString();
      return false;
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    isSpeaking = false;
    isPaused = false;
    _lastSpokenText = null;
    _resumeOffset = 0;
    _lastProgressEnd = 0;
    _progressCallback = null;
    _completionCallback = null;
  }
}
