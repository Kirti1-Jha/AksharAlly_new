import 'dart:async';

import 'package:aksharally_ui/screens/login_screen.dart';
import 'package:aksharally_ui/services/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginScreen welcome narration', () {
    testWidgets(
      'plays once on entry, survives mode changes, and replays on request',
      (tester) async {
        final engine = _LoginTtsEngine();
        final service = TTSService(engine: engine);

        await tester.pumpWidget(
          MaterialApp(home: LoginScreen(ttsService: service)),
        );
        await tester.pumpAndSettle();

        expect(engine.spoken, [LoginScreen.welcomeMessage]);
        expect(engine.language, 'en-IN');

        await tester.tap(find.text('Register').first);
        await tester.pumpAndSettle();
        expect(engine.spoken, [LoginScreen.welcomeMessage]);

        await tester.tap(find.text('Replay welcome message'));
        await tester.pumpAndSettle();
        expect(engine.spoken, [
          LoginScreen.welcomeMessage,
          LoginScreen.welcomeMessage,
        ]);

        await service.speak('Reader playback after the welcome.');
        expect(engine.spoken.last, 'Reader playback after the welcome.');
      },
    );

    testWidgets('reports an en-IN fallback without blocking the screen', (
      tester,
    ) async {
      final engine = _LoginTtsEngine(availableLocales: {'en-US'});
      final service = TTSService(engine: engine);

      await tester.pumpWidget(
        MaterialApp(home: LoginScreen(ttsService: service)),
      );
      await tester.pumpAndSettle();

      expect(engine.spoken, [LoginScreen.welcomeMessage]);
      expect(engine.language, 'en-US');
      expect(
        find.text('Preferred locale en-IN is unavailable; using en-US.'),
        findsOneWidget,
      );
      expect(find.text('Replay welcome message'), findsOneWidget);
    });

    testWidgets('does not speak if the screen closes during initialization', (
      tester,
    ) async {
      final engine = _LoginTtsEngine();
      final availability = Completer<bool>();
      engine.availabilityGate = availability;
      final service = TTSService(engine: engine);

      await tester.pumpWidget(
        MaterialApp(home: LoginScreen(ttsService: service)),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());

      availability.complete(true);
      await tester.pump();
      await tester.pump();

      expect(engine.spoken, isEmpty);
    });
  });
}

class _LoginTtsEngine implements TtsEngine {
  _LoginTtsEngine({Set<String>? availableLocales})
    : availableLocales =
          availableLocales ?? {'en-IN', 'en-US', 'hi-IN', 'mr-IN'};

  final Set<String> availableLocales;
  final List<String> spoken = [];
  Completer<bool>? availabilityGate;
  String? language;
  void Function()? _startHandler;

  @override
  Future<bool> isLanguageAvailable(String locale) async {
    final gate = availabilityGate;
    if (gate != null) return gate.future;
    return availableLocales.contains(locale);
  }

  @override
  Future<List<Map<String, dynamic>>> getVoices() async => availableLocales
      .map((locale) => <String, dynamic>{
            'name': 'Device $locale',
            'locale': locale,
          })
      .toList();

  @override
  Future<void> setVoice(Map<String, String> voice) async {}

  @override
  Future<void> setLanguage(String locale) async {
    language = locale;
  }

  @override
  Future<void> setSpeechRate(double rate) async {}

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
  void setProgressHandler(TTSProgressCallback callback) {}

  @override
  void setErrorHandler(TTSErrorCallback callback) {}
}
