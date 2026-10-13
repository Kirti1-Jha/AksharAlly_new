import 'package:flutter_tts/flutter_tts.dart';

typedef TTSProgressCallback =
    void Function(String text, int start, int end, String word);

typedef TTSErrorCallback = void Function(Object? error);

/// Small seam around the platform plugin so pause/resume logic can be tested
/// without invoking a device TTS engine.
abstract interface class TtsEngine {
  Future<bool> isLanguageAvailable(String locale);
  Future<List<Map<String, dynamic>>> getVoices();
  Future<void> setVoice(Map<String, String> voice);
  Future<void> clearVoice();
  Future<void> setLanguage(String locale);
  Future<void> setSpeechRate(double rate);
  Future<void> setPitch(double pitch);
  Future<void> setVolume(double volume);
  Future<void> speak(String text);
  Future<bool> pause();
  Future<void> stop();
  void setStartHandler(void Function() callback);
  void setCompletionHandler(void Function() callback);
  void setCancelHandler(void Function() callback);
  void setPauseHandler(void Function() callback);
  void setContinueHandler(void Function() callback);
  void setProgressHandler(TTSProgressCallback callback);
  void setErrorHandler(TTSErrorCallback callback);
}

class FlutterTtsEngine implements TtsEngine {
  FlutterTtsEngine([FlutterTts? flutterTts]) : _tts = flutterTts ?? FlutterTts();

  final FlutterTts _tts;

  @override
  Future<bool> isLanguageAvailable(String locale) async =>
      await _tts.isLanguageAvailable(locale) == true;

  @override
  Future<List<Map<String, dynamic>>> getVoices() async {
    final result = await _tts.getVoices;
    if (result is! List) return const [];
    return result
        .whereType<Map>()
        .map((voice) => Map<String, dynamic>.from(voice))
        .toList();
  }

  @override
  Future<void> setVoice(Map<String, String> voice) async {
    await _tts.setVoice(voice);
  }

  @override
  Future<void> clearVoice() async {
    await _tts.clearVoice();
  }

  @override
  Future<void> setLanguage(String locale) async {
    await _tts.setLanguage(locale);
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }

  @override
  Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _tts.setVolume(volume);
  }

  @override
  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  @override
  Future<bool> pause() async {
    final result = await _tts.pause();
    return result == true || result == 1;
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  @override
  void setStartHandler(void Function() callback) =>
      _tts.setStartHandler(callback);

  @override
  void setCompletionHandler(void Function() callback) =>
      _tts.setCompletionHandler(callback);

  @override
  void setCancelHandler(void Function() callback) =>
      _tts.setCancelHandler(callback);

  @override
  void setPauseHandler(void Function() callback) =>
      _tts.setPauseHandler(callback);

  @override
  void setContinueHandler(void Function() callback) =>
      _tts.setContinueHandler(callback);

  @override
  void setProgressHandler(TTSProgressCallback callback) =>
      _tts.setProgressHandler(callback);

  @override
  void setErrorHandler(TTSErrorCallback callback) =>
      _tts.setErrorHandler((dynamic message) => callback(message));
}

class TTSService {
  TTSService({TtsEngine? engine}) : _engine = engine ?? FlutterTtsEngine();

  static const preferredEnglishLocale = 'en-IN';
  static const fallbackEnglishLocale = 'en-US';

  /// Returns a content locale only for a language the app explicitly knows.
  /// A null result means callers should keep the device's system voice.
  static String? localeForLanguage(String? language) {
    final languageCode = language?.toLowerCase().split(RegExp('[-_]')).first;
    return switch (languageCode) {
      'en' => preferredEnglishLocale,
      'hi' => 'hi-IN',
      'mr' => 'mr-IN',
      _ => null,
    };
  }

  final TtsEngine _engine;

  bool isSpeaking = false;
  bool isPaused = false;
  double _speechRate = 0.4;
  String? _lastSpokenText;
  int _resumeOffset = 0;
  int _segmentStartOffset = 0;
  int _lastProgressStart = 0;
  int _generation = 0;
  bool _hasActiveUtterance = false;
  bool _hasStarted = false;
  bool _rateChangedWhilePaused = false;
  bool _fallbackResumeOffsetPending = false;
  TTSProgressCallback? _progressCallback;
  void Function()? _completionCallback;
  TTSErrorCallback? _utteranceErrorCallback;
  Future<void>? _initFuture;
  String? lastError;
  String? _currentLocale;
  String? _localeNotice;

  String? get currentLocale => _currentLocale;
  String? get localeNotice => _localeNotice;

  /// Configure the platform handlers once for this reader session.
  ///
  /// If [defaultLocale] is null, leave locale selection to the device. This is
  /// used for saved content without language metadata rather than guessing it
  /// is English.
  Future<void> init({
    String? defaultLocale = preferredEnglishLocale,
  }) async {
    final pendingInitialization = _initFuture;
    if (pendingInitialization != null) {
      await pendingInitialization;
      return;
    }

    final initialization = _initialize(defaultLocale);
    _initFuture = initialization;
    try {
      await initialization;
    } catch (_) {
      if (identical(_initFuture, initialization)) _initFuture = null;
      rethrow;
    }
  }

  Future<void> _initialize(String? defaultLocale) async {
    if (defaultLocale != null) await setLanguage(defaultLocale);
    await _engine.setSpeechRate(_speechRate);
    await _engine.setPitch(1.0);
    await _engine.setVolume(1.0);

    _engine.setStartHandler(() {
      if (!_hasActiveUtterance) return;
      _hasStarted = true;
      isSpeaking = true;
      isPaused = false;
    });

    _engine.setCompletionHandler(() {
      if (!_hasActiveUtterance || !_hasStarted) return;
      _hasActiveUtterance = false;
      isSpeaking = false;
      isPaused = false;
      final callback = _completionCallback;
      _progressCallback = null;
      _completionCallback = null;
      _utteranceErrorCallback = null;
      callback?.call();
    });

    _engine.setCancelHandler(() {
      if (!_hasActiveUtterance || !_hasStarted || isPaused) return;
      _hasActiveUtterance = false;
      isSpeaking = false;
      isPaused = false;
      _progressCallback = null;
      _completionCallback = null;
      _utteranceErrorCallback = null;
    });

    _engine.setPauseHandler(() {
      if (!_hasActiveUtterance) return;
      _resumeOffset = _lastProgressStart;
      isSpeaking = false;
      isPaused = true;
    });

    _engine.setContinueHandler(() {
      if (!_hasActiveUtterance) return;
      isSpeaking = true;
      isPaused = false;
    });

    _engine.setProgressHandler(_handleProgress);
    _engine.setErrorHandler((error) {
      if (!_hasActiveUtterance) return;
      _hasActiveUtterance = false;
      isSpeaking = false;
      isPaused = false;
      _progressCallback = null;
      _completionCallback = null;
      final callback = _utteranceErrorCallback;
      _utteranceErrorCallback = null;
      lastError = error.toString();
      callback?.call(error);
    });
  }

  void _handleProgress(String reportedText, int start, int end, String word) {
    if (!_hasActiveUtterance || !_hasStarted || isPaused) return;
    final originalText = _lastSpokenText;
    if (originalText == null) return;
    if (_segmentStartOffset > 0 && reportedText == originalText) return;

    final baseOffset = _baseOffsetFor(reportedText, originalText);
    if (baseOffset == null) return;
    final globalStart = (baseOffset + start)
        .clamp(0, originalText.length)
        .toInt();
    final globalEnd = (baseOffset + end)
        .clamp(globalStart, originalText.length)
        .toInt();
    if (globalStart < _lastProgressStart) return;

    _lastProgressStart = globalStart;
    _resumeOffset = globalStart;
    _progressCallback?.call(originalText, globalStart, globalEnd, word);
  }

  int? _baseOffsetFor(String reportedText, String originalText) {
    if (reportedText == originalText) return 0;
    final resumeSearchFrom =
        _resumeOffset.clamp(0, originalText.length).toInt();
    final resumedMatch = originalText.indexOf(reportedText, resumeSearchFrom);
    if (resumedMatch >= 0) return resumedMatch;
    final segmentSearchFrom =
        _segmentStartOffset.clamp(0, originalText.length).toInt();
    final segmentMatch = originalText.indexOf(reportedText, segmentSearchFrom);
    return segmentMatch >= 0 ? segmentMatch : null;
  }

  /// Applies a bounded speech rate. If speech is active, only the remaining
  /// text from the current word is restarted so platforms that snapshot rate
  /// per utterance (notably iOS) actually use the new rate.
  Future<double> setRate(double rate) async {
    final boundedRate = rate.clamp(0.1, 1.0).toDouble();
    final wasSpeaking = isSpeaking && _hasActiveUtterance;
    final wasPaused = isPaused && _hasActiveUtterance;
    await _engine.setSpeechRate(boundedRate);
    _speechRate = boundedRate;

    if (wasPaused) {
      _rateChangedWhilePaused = true;
    } else if (wasSpeaking) {
      await _startSegmentFrom(_lastProgressStart);
    }
    return _speechRate;
  }

  double get currentRate => _speechRate;

  /// Supplies an estimated word start when the engine has no word-level
  /// callbacks. The next pause/resume restarts from this word boundary rather
  /// than replaying the full utterance on engines without native pause offsets.
  void setFallbackResumeOffset(int offset) {
    final text = _lastSpokenText;
    if (text == null || !_hasActiveUtterance) return;
    final safeOffset = offset.clamp(0, text.length).toInt();
    _resumeOffset = safeOffset;
    _lastProgressStart = safeOffset;
    _fallbackResumeOffsetPending = true;
  }

  /// Changes the output voice only when the locale is available or an
  /// installed matching voice can be enumerated on this platform.
  Future<bool> setLanguage(String localeId) async {
    final locale = localeId.replaceAll('_', '-');
    if (_normalizeLocale(locale) == preferredEnglishLocale.toLowerCase()) {
      return _setPreferredEnglish();
    }

    _localeNotice = null;
    try {
      final voice = await _findVoiceForLocale(locale);
      final availability = await _isLocaleAvailable(locale, voice);
      if (availability == false) {
        _localeNotice = 'Speech locale $locale is unavailable on this device.';
        return false;
      }
      await _engine.setLanguage(locale);
      _currentLocale = locale;
      if (availability == null) {
        _localeNotice =
            'Locale $locale was requested, but this device does not expose '
            'enough voice details to verify its accent.';
      }
      if (voice != null) await _applyVoice(voice);
      return true;
    } catch (error) {
      lastError = error.toString();
      _localeNotice = 'Speech locale $locale could not be selected.';
      return false;
    }
  }

  /// Clears an explicit locale/voice selection so later untagged text uses the
  /// device's default voice instead of inheriting a previous screen's choice.
  Future<bool> resetVoiceToDefault() async {
    try {
      if (_hasActiveUtterance) {
        try {
          await stop();
        } catch (_) {
          // Still try to clear the selected voice if stop already failed.
        }
      }
      await _engine.clearVoice();
      _currentLocale = null;
      _localeNotice = null;
      return true;
    } catch (error) {
      lastError = error.toString();
      return false;
    }
  }

  Future<bool> _setPreferredEnglish() async {
    _localeNotice = null;
    try {
      final voice = await _findVoiceForLocale(preferredEnglishLocale);
      final availability = await _isLocaleAvailable(
        preferredEnglishLocale,
        voice,
      );
      if (availability != false) {
        await _engine.setLanguage(preferredEnglishLocale);
        _currentLocale = preferredEnglishLocale;
        if (availability == null) {
          _localeNotice =
              'Locale en-IN was requested, but this device does not expose '
              'enough voice details to verify its accent.';
        }
        if (voice != null) await _applyVoice(voice);
        return true;
      }
    } catch (error) {
      lastError = error.toString();
    }

    try {
      final fallbackVoice = await _findVoiceForLocale(fallbackEnglishLocale);
      final availability = await _isLocaleAvailable(
        fallbackEnglishLocale,
        fallbackVoice,
      );
      if (availability != false) {
        await _engine.setLanguage(fallbackEnglishLocale);
        _currentLocale = fallbackEnglishLocale;
        if (fallbackVoice != null) await _applyVoice(fallbackVoice);
        _localeNotice =
            'Preferred locale en-IN is unavailable; using en-US.';
        return true;
      }
    } catch (error) {
      lastError = error.toString();
    }

    _currentLocale = null;
    _localeNotice = 'Neither en-IN nor en-US is available on this device.';
    return false;
  }

  Future<bool?> _isLocaleAvailable(
    String locale,
    Map<String, dynamic>? matchingVoice,
  ) async {
    try {
      return await _engine.isLanguageAvailable(locale) ||
          matchingVoice != null;
    } catch (error) {
      lastError = error.toString();
      return matchingVoice == null ? null : true;
    }
  }

  Future<Map<String, dynamic>?> _findVoiceForLocale(String locale) async {
    try {
      final normalizedLocale = _normalizeLocale(locale);
      for (final voice in await _engine.getVoices()) {
        final voiceLocale = voice['locale'];
        if (voiceLocale is String &&
            _normalizeLocale(voiceLocale) == normalizedLocale) {
          return voice;
        }
      }
    } catch (error) {
      // Voice enumeration is not supported by every platform. Locale
      // availability can still be checked independently.
      lastError ??= error.toString();
    }
    return null;
  }

  Future<void> _applyVoice(Map<String, dynamic> voice) async {
    final selection = <String, String>{};
    for (final key in ['name', 'locale', 'identifier']) {
      final value = voice[key];
      if (value is String && value.isNotEmpty) selection[key] = value;
    }
    if (selection.isEmpty) return;
    try {
      await _engine.setVoice(selection);
    } catch (error) {
      // Keep the selected locale and let the platform choose its default
      // voice for that locale if explicit voice selection is unsupported.
      lastError ??= error.toString();
    }
  }

  String _normalizeLocale(String locale) =>
      locale.replaceAll('_', '-').toLowerCase();

  Future<void> speak(
    String text, {
    TTSProgressCallback? onProgress,
    void Function()? onComplete,
    TTSErrorCallback? onError,
  }) async {
    if (text.isEmpty) return;

    final generation = ++_generation;
    _hasActiveUtterance = false;
    isSpeaking = false;
    isPaused = false;
    _progressCallback = null;
    _completionCallback = null;
    await _engine.stop();
    if (generation != _generation) return;

    _lastSpokenText = text;
    _resumeOffset = 0;
    _segmentStartOffset = 0;
    _lastProgressStart = 0;
    _rateChangedWhilePaused = false;
    _fallbackResumeOffsetPending = false;
    _progressCallback = onProgress;
    _completionCallback = onComplete;
    _utteranceErrorCallback = onError;
    _hasStarted = false;
    _hasActiveUtterance = true;
    lastError = null;
    await _engine.speak(text);
    if (generation == _generation &&
        _hasActiveUtterance &&
        !isPaused &&
        !isSpeaking) {
      isSpeaking = true;
    }
  }

  Future<bool> pause() async {
    if (isPaused) return true;
    if (!isSpeaking || !_hasActiveUtterance) return false;
    final generation = _generation;
    try {
      final paused = await _engine.pause();
      if (generation != _generation || !_hasActiveUtterance) return false;
      if (!paused) return false;
      _resumeOffset = _lastProgressStart;
      isSpeaking = false;
      isPaused = true;
      return true;
    } catch (error) {
      lastError = error.toString();
      // A failed native pause must not make active speech look paused. The
      // caller can keep the current playback and highlight timer running.
      return false;
    }
  }

  /// FlutterTts resumes its paused utterance when speak is called again.
  ///
  /// If the rate changed while paused, restart only the remaining suffix. This
  /// preserves Android's/iOS's pause point while applying the new rate.
  Future<bool> resume() async {
    final text = _lastSpokenText;
    if (!isPaused || text == null || text.isEmpty || !_hasActiveUtterance) {
      return false;
    }
    if (_rateChangedWhilePaused || _fallbackResumeOffsetPending) {
      return _startSegmentFrom(_resumeOffset);
    }

    final generation = _generation;
    try {
      isPaused = false;
      isSpeaking = true;
      await _engine.speak(text);
      if (generation != _generation || !_hasActiveUtterance) return false;
      if (!isPaused) isSpeaking = true;
      return true;
    } catch (error) {
      lastError = error.toString();
      return false;
    }
  }

  Future<bool> _startSegmentFrom(int offset) async {
    final text = _lastSpokenText;
    if (text == null || text.isEmpty) return false;
    final generation = ++_generation;
    final safeOffset = offset.clamp(0, text.length).toInt();
    _hasActiveUtterance = false;
    isSpeaking = false;
    isPaused = false;
    try {
      await _engine.stop();
      if (generation != _generation) return false;

      _segmentStartOffset = safeOffset;
      _resumeOffset = safeOffset;
      _lastProgressStart = safeOffset;
      _hasStarted = false;
      _hasActiveUtterance = true;
      _rateChangedWhilePaused = false;
      _fallbackResumeOffsetPending = false;
      await _engine.speak(text.substring(safeOffset));
      if (generation != _generation || !_hasActiveUtterance) return false;
      if (!isPaused) isSpeaking = true;
      return true;
    } catch (error) {
      if (generation == _generation) {
        _hasActiveUtterance = false;
        isSpeaking = false;
        isPaused = false;
        _progressCallback = null;
        _completionCallback = null;
        _utteranceErrorCallback = null;
        lastError = error.toString();
      }
      return false;
    }
  }

  Future<void> stop() async {
    ++_generation;
    _hasActiveUtterance = false;
    _hasStarted = false;
    isSpeaking = false;
    isPaused = false;
    _lastSpokenText = null;
    _resumeOffset = 0;
    _segmentStartOffset = 0;
    _lastProgressStart = 0;
    _rateChangedWhilePaused = false;
    _fallbackResumeOffsetPending = false;
    _progressCallback = null;
    _completionCallback = null;
    _utteranceErrorCallback = null;
    await _engine.stop();
  }
}
