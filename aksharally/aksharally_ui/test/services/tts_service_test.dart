import 'package:aksharally_ui/services/tts_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TTSService playback speed', () {
    test('maps the supported multipliers to normalized engine rates', () {
      expect(TTSService.playbackSpeeds, [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]);
      expect(TTSService.engineRateForPlaybackSpeed(0.5), closeTo(0.2, 1e-9));
      expect(TTSService.engineRateForPlaybackSpeed(1.0), closeTo(0.4, 1e-9));
      expect(TTSService.engineRateForPlaybackSpeed(2.0), closeTo(0.8, 1e-9));
      expect(TTSService.playbackSpeedForEngineRate(0.4), 1.0);
    });

    test(
      'changing speed while paused does not resume until requested',
      () async {
        final engine = _FakeTtsEngine();
        final service = TTSService(engine: engine);
        await service.init(defaultLocale: null);

        await service.speak('one two three');
        engine.emitProgress('one two three', 4, 7, 'two');
        expect(await service.pause(), isTrue);
        expect(service.isPaused, isTrue);

        await service.setRate(TTSService.engineRateForPlaybackSpeed(1.5));

        expect(engine.speechRate, closeTo(0.6, 1e-9));
        expect(engine.spoken, ['one two three']);
        expect(service.isPaused, isTrue);

        expect(await service.resume(), isTrue);
        expect(engine.spoken, ['one two three', 'two three']);
        expect(service.isPaused, isFalse);
      },
    );

    test(
      'estimated resume offsets do not reject later native progress',
      () async {
        final engine = _FakeTtsEngine();
        final service = TTSService(engine: engine);
        final progressStarts = <int>[];
        await service.init(defaultLocale: null);

        await service.speak(
          'one two three',
          onProgress: (_, start, __, ___) => progressStarts.add(start),
        );
        engine.emitProgress('one two three', 0, 3, 'one');
        service.setFallbackResumeOffset(4);
        engine.emitProgress('one two three', 0, 3, 'one');

        expect(progressStarts, [0, 0]);
      },
    );

    test('stopped sessions ignore later progress callbacks', () async {
      final engine = _FakeTtsEngine();
      final service = TTSService(engine: engine);
      final progressStarts = <int>[];
      await service.init(defaultLocale: null);

      await service.speak(
        'one two',
        onProgress: (_, start, __, ___) => progressStarts.add(start),
      );
      await service.stop();
      engine.emitProgress('one two', 0, 3, 'one');

      expect(progressStarts, isEmpty);
    });
  });
}

class _FakeTtsEngine implements TtsEngine {
  final List<String> spoken = [];
  double? speechRate;
  void Function()? _startHandler;
  TTSProgressCallback? _progressHandler;

  void emitProgress(String text, int start, int end, String word) {
    _progressHandler?.call(text, start, end, word);
  }

  @override
  Future<bool> isLanguageAvailable(String locale) async => true;

  @override
  Future<List<Map<String, dynamic>>> getVoices() async => const [];

  @override
  Future<void> setVoice(Map<String, String> voice) async {}

  @override
  Future<void> clearVoice() async {}

  @override
  Future<void> setLanguage(String locale) async {}

  @override
  Future<void> setSpeechRate(double rate) async {
    speechRate = rate;
  }

  @override
  Future<void> setPitch(double pitch) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
    _startHandler?.call();
  }

  @override
  Future<bool> pause() async => true;

  @override
  Future<void> stop() async {}

  @override
  void setStartHandler(void Function() callback) => _startHandler = callback;

  @override
  void setCompletionHandler(void Function() callback) {}

  @override
  void setCancelHandler(void Function() callback) {}

  @override
  void setPauseHandler(void Function() callback) {}

  @override
  void setContinueHandler(void Function() callback) {}

  @override
  void setProgressHandler(TTSProgressCallback callback) =>
      _progressHandler = callback;

  @override
  void setErrorHandler(TTSErrorCallback callback) {}
}
