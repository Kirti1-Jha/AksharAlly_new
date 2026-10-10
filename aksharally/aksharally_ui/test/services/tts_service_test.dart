import 'dart:async';

import 'package:aksharally_ui/services/tts_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TTSService', () {
    late _FakeTtsEngine engine;
    late TTSService service;

    setUp(() async {
      engine = _FakeTtsEngine();
      service = TTSService(engine: engine);
      await service.init();
    });

    test('normalizes Android-style resumed progress offsets', () async {
      const text = 'पहला शब्द, फिर एक नया शब्द।';
      final progress = <int>[];
      await service.speak(
        text,
        onProgress: (_, start, __, ___) => progress.add(start),
      );

      final resumeAt = text.indexOf('फिर');
      engine.emitRange(resumeAt, resumeAt + 'फिर'.length);
      expect(await service.pause(), isTrue);
      expect(await service.resume(), isTrue);

      final resumedWord = text.indexOf('नया');
      final localWordOffset = resumedWord - resumeAt;
      engine.emitRange(localWordOffset, localWordOffset + 'नया'.length);

      expect(progress.last, resumedWord);
      expect(engine.activeSegment, text.substring(resumeAt));
    });

    test('rate changes while paused restart from the current word only', () async {
      const text = 'पहला शब्द और फिर आगे पढ़ना।';
      await service.speak(text);

      final currentWord = text.indexOf('फिर');
      engine.emitRange(currentWord, currentWord + 'फिर'.length);
      await service.pause();
      await service.setRate(0.7);

      expect(service.isPaused, isTrue);
      expect(await service.resume(), isTrue);
      expect(engine.activeSegment, text.substring(currentWord));
      expect(service.currentRate, 0.7);
    });

    test('fallback offset resumes at its estimated word boundary', () async {
      const text = 'एकूण मजकूर पुढे वाचायचा आहे.';
      await service.speak(text);

      final estimatedWord = text.indexOf('पुढे');
      service.setFallbackResumeOffset(estimatedWord);
      await service.pause();
      expect(await service.resume(), isTrue);

      expect(engine.activeSegment, text.substring(estimatedWord));
    });

    test('rate changes during speech restart only the remaining suffix', () async {
      const text = 'पहले शब्द फिर आगे पढ़ना।';
      await service.speak(text);

      final currentWord = text.indexOf('आगे');
      engine.emitRange(currentWord, currentWord + 'आगे'.length);
      await service.setRate(0.6);

      expect(engine.activeSegment, text.substring(currentWord));
      expect(engine.speechRates.last, 0.6);
    });

    test('stop ignores late progress and completion callbacks', () async {
      var progressCount = 0;
      var completionCount = 0;
      await service.speak(
        'पहला शब्द फिर दूसरा शब्द।',
        onProgress: (_, __, ___, ____) => progressCount++,
        onComplete: () => completionCount++,
      );
      engine.emitRange(0, 'पहला'.length);
      await service.stop();

      engine.emitRange('पहला '.length, 'पहला शब्द'.length);
      engine.complete();

      expect(progressCount, 1);
      expect(completionCount, 0);
      expect(service.isSpeaking, isFalse);
      expect(service.isPaused, isFalse);
    });

    test('pause failure leaves the active utterance playing', () async {
      await service.speak('Continue reading this passage.');
      engine.pauseError = StateError('pause not supported');

      expect(await service.pause(), isFalse);
      expect(service.isSpeaking, isTrue);
      expect(service.isPaused, isFalse);
      expect(service.lastError, contains('pause not supported'));
    });

    test('late pause result cannot pause a newer utterance', () async {
      await service.speak('First passage.');
      final pauseGate = Completer<bool>();
      engine.pauseGate = pauseGate;
      final pendingPause = service.pause();

      await service.speak('Second passage.');
      pauseGate.complete(true);

      expect(await pendingPause, isFalse);
      expect(service.isSpeaking, isTrue);
      expect(service.isPaused, isFalse);
      expect(engine.activeSegment, 'Second passage.');
    });

    test(
      'progress from a previous text does not highlight a new utterance',
      () async {
        var progressCount = 0;
        await service.speak(
          'First passage.',
          onProgress: (_, __, ___, ____) => progressCount++,
        );
        await service.speak(
          'Different passage.',
          onProgress: (_, __, ___, ____) => progressCount++,
        );

        engine.emitProgressFor('First passage.', 0, 5);

        expect(progressCount, 0);
      },
    );

    test('initialization registers only one set of platform listeners', () async {
      await service.init();
      await service.init();

      expect(engine.progressHandlerRegistrations, 1);
      expect(engine.startHandlerRegistrations, 1);
    });
  });
}

class _FakeTtsEngine implements TtsEngine {
  String? language;
  double? speechRate;
  String activeSegment = '';
  String? _originalText;
  String? _pausedSegment;
  int _lastLocalProgressStart = 0;
  bool _speaking = false;
  bool _paused = false;
  Object? pauseError;
  Completer<bool>? pauseGate;

  void Function()? _startHandler;
  void Function()? _completionHandler;
  void Function()? _cancelHandler;
  void Function()? _pauseHandler;
  void Function()? _continueHandler;
  TTSProgressCallback? _progressHandler;
  TTSErrorCallback? _errorHandler;

  int progressHandlerRegistrations = 0;
  int startHandlerRegistrations = 0;
  final spokenSegments = <String>[];
  final speechRates = <double>[];

  @override
  Future<bool> isLanguageAvailable(String locale) async => true;

  @override
  Future<void> setLanguage(String locale) async {
    language = locale;
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    speechRate = rate;
    speechRates.add(rate);
  }

  @override
  Future<void> setPitch(double pitch) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> speak(String text) async {
    if (_paused && text == _originalText) {
      activeSegment = _pausedSegment ?? text;
      _paused = false;
      _speaking = true;
      _continueHandler?.call();
    } else {
      activeSegment = text;
      _originalText = text;
      _lastLocalProgressStart = 0;
      _paused = false;
      _speaking = true;
      _startHandler?.call();
    }
    spokenSegments.add(activeSegment);
  }

  @override
  Future<bool> pause() async {
    if (pauseError != null) throw pauseError!;
    final gate = pauseGate;
    if (gate != null) return gate.future;
    if (!_speaking) return false;
    final safeStart = _lastLocalProgressStart
        .clamp(0, activeSegment.length)
        .toInt();
    _pausedSegment = activeSegment.substring(safeStart);
    _paused = true;
    _speaking = false;
    _pauseHandler?.call();
    return true;
  }

  @override
  Future<void> stop() async {
    final wasActive = _speaking || _paused;
    _speaking = false;
    _paused = false;
    _pausedSegment = null;
    if (wasActive) _cancelHandler?.call();
  }

  void emitRange(int start, int end) {
    emitProgressFor(activeSegment, start, end);
  }

  void emitProgressFor(String text, int start, int end) {
    _lastLocalProgressStart = start;
    _progressHandler?.call(text, start, end, text.substring(start, end));
  }

  void complete() {
    _speaking = false;
    _completionHandler?.call();
  }

  void emitError(Object error) => _errorHandler?.call(error);

  @override
  void setStartHandler(void Function() callback) {
    startHandlerRegistrations++;
    _startHandler = callback;
  }

  @override
  void setCompletionHandler(void Function() callback) {
    _completionHandler = callback;
  }

  @override
  void setCancelHandler(void Function() callback) {
    _cancelHandler = callback;
  }

  @override
  void setPauseHandler(void Function() callback) {
    _pauseHandler = callback;
  }

  @override
  void setContinueHandler(void Function() callback) {
    _continueHandler = callback;
  }

  @override
  void setProgressHandler(TTSProgressCallback callback) {
    progressHandlerRegistrations++;
    _progressHandler = callback;
  }

  @override
  void setErrorHandler(TTSErrorCallback callback) {
    _errorHandler = callback;
  }
}
