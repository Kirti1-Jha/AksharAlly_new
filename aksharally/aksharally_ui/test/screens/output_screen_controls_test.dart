import 'package:aksharally_ui/screens/output_screen.dart';
import 'package:aksharally_ui/services/tts_service.dart';
import 'package:aksharally_ui/theme/accessibility_settings.dart';
import 'package:aksharally_ui/theme/app_settings.dart';
import 'package:aksharally_ui/widgets/highlighted_text_view.dart';
import 'package:aksharally_ui/widgets/voice_assistant_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AppSettings.speechRate = 0.4;
    AppSettings.voiceAssistanceEnabled = false;
    AccessibilitySettings.fontFamily = 'System Default';
  });

  Future<void> pumpOutputScreen(
    WidgetTester tester,
    _FakeOutputTtsEngine engine,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: OutputScreen(
          displayText: 'one two three four.',
          readingLanguage: 'en',
          ttsService: TTSService(engine: engine),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('OutputScreen playback controls', () {
    testWidgets(
      'shows 1.0× by default and clamps manual rate changes',
      (tester) async {
        final engine = _FakeOutputTtsEngine();
        await pumpOutputScreen(tester, engine);

        expect(find.text('1.0×'), findsOneWidget);

        for (var tap = 0; tap < 15; tap++) {
          await tester.tap(find.byKey(const ValueKey('speech-rate-faster')));
          await tester.pumpAndSettle();
        }
        expect(find.text('2.5×'), findsOneWidget);
        expect(engine.speechRate, closeTo(1.0, 0.000001));

        for (var tap = 0; tap < 18; tap++) {
          await tester.tap(find.byKey(const ValueKey('speech-rate-slower')));
          await tester.pumpAndSettle();
        }
        expect(find.text('0.3×'), findsOneWidget);
        expect(engine.speechRate, closeTo(0.1, 0.000001));
      },
    );

    testWidgets(
      'queues manual rate changes during playback and preserves word progress',
      (tester) async {
        final engine = _FakeOutputTtsEngine();
        await pumpOutputScreen(tester, engine);

        await tester.tap(find.text('Start'));
        await tester.pumpAndSettle();
        expect(engine.isSpeaking, isTrue);

        final firstWord = engine.activeSegment.indexOf('one');
        engine.emitRange(firstWord, firstWord + 'one'.length);
        await tester.pump();
        expect(
          tester.widget<HighlightedTextView>(
            find.byType(HighlightedTextView),
          ).currentIndex,
          0,
        );

        final secondWord = engine.activeSegment.indexOf('two');
        engine.emitRange(secondWord, secondWord + 'two'.length);
        await tester.pump();
        expect(
          tester.widget<HighlightedTextView>(
            find.byType(HighlightedTextView),
          ).currentIndex,
          1,
        );

        await tester.tap(find.byKey(const ValueKey('speech-rate-faster')));
        await tester.pumpAndSettle();
        expect(find.text('1.1×'), findsOneWidget);
        expect(engine.spokenSegments, ['one two three four.']);
        expect(engine.speechRate, closeTo(0.4, 0.000001));

        final thirdWord = engine.activeSegment.indexOf('three');
        engine.emitRange(thirdWord, thirdWord + 'three'.length);
        await tester.pump();
        expect(
          tester.widget<HighlightedTextView>(
            find.byType(HighlightedTextView),
          ).currentIndex,
          2,
        );

        engine.complete();
        await tester.pumpAndSettle();
        expect(engine.speechRate, closeTo(0.45, 0.000001));

        await tester.tap(find.text('Start'));
        await tester.pumpAndSettle();
        expect(engine.spokenSegments, [
          'one two three four.',
          'one two three four.',
        ]);
        expect(engine.speechRate, closeTo(0.45, 0.000001));
      },
    );

    testWidgets(
      'rate selected while paused is retained on resume',
      (tester) async {
        final engine = _FakeOutputTtsEngine();
        await pumpOutputScreen(tester, engine);

        await tester.tap(find.text('Start'));
        await tester.pumpAndSettle();
        final text = engine.activeSegment;
        final secondWord = text.indexOf('two');
        engine.emitRange(secondWord, secondWord + 'two'.length);
        await tester.pump();

        await tester.tap(find.text('Pause'));
        await tester.pumpAndSettle();
        expect(engine.isSpeaking, isFalse);

        await tester.tap(find.byKey(const ValueKey('speech-rate-faster')));
        await tester.pumpAndSettle();
        expect(engine.speechRate, closeTo(0.45, 0.000001));

        await tester.tap(find.text('Resume'));
        await tester.pumpAndSettle();
        expect(engine.isSpeaking, isTrue);
        expect(engine.activeSegment, text.substring(secondWord));
        expect(engine.speechRate, closeTo(0.45, 0.000001));
      },
    );

    testWidgets(
      'voice controls open on demand without interrupting TTS',
      (tester) async {
        final engine = _FakeOutputTtsEngine();
        await pumpOutputScreen(tester, engine);

        expect(find.byType(VoiceAssistantControls), findsNothing);
        await tester.tap(find.text('Start'));
        await tester.pumpAndSettle();
        expect(engine.isSpeaking, isTrue);

        await tester.tap(find.byKey(const ValueKey('voice-commands-button')));
        await tester.pumpAndSettle();
        expect(find.byType(VoiceAssistantControls), findsOneWidget);
        expect(engine.isSpeaking, isTrue);

        await tester.tap(find.byKey(const ValueKey('close-voice-commands')));
        await tester.pumpAndSettle();
        expect(find.byType(VoiceAssistantControls), findsNothing);
        expect(engine.isSpeaking, isTrue);
        expect(engine.spokenSegments, ['one two three four.']);
      },
    );
  });
}

class _FakeOutputTtsEngine implements TtsEngine {
  double speechRate = 0.4;
  String activeSegment = '';
  bool isSpeaking = false;
  bool _isPaused = false;
  final List<String> spokenSegments = [];

  void Function()? _startHandler;
  void Function()? _completionHandler;
  void Function()? _cancelHandler;
  void Function()? _pauseHandler;
  TTSProgressCallback? _progressHandler;

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
    activeSegment = text;
    spokenSegments.add(text);
    _isPaused = false;
    isSpeaking = true;
    _startHandler?.call();
  }

  @override
  Future<bool> pause() async {
    if (!isSpeaking) return false;
    isSpeaking = false;
    _isPaused = true;
    _pauseHandler?.call();
    return true;
  }

  @override
  Future<void> stop() async {
    final wasActive = isSpeaking || _isPaused;
    isSpeaking = false;
    _isPaused = false;
    if (wasActive) _cancelHandler?.call();
  }

  void emitRange(int start, int end) {
    _progressHandler?.call(
      activeSegment,
      start,
      end,
      activeSegment.substring(start, end),
    );
  }

  void complete() {
    isSpeaking = false;
    _isPaused = false;
    _completionHandler?.call();
  }

  @override
  void setStartHandler(void Function() callback) {
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
  void setContinueHandler(void Function() callback) {}

  @override
  void setProgressHandler(TTSProgressCallback callback) {
    _progressHandler = callback;
  }

  @override
  void setErrorHandler(TTSErrorCallback callback) {}
}
