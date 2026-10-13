import 'dart:async';

import 'package:aksharally_ui/services/auth_flow.dart';
import 'package:aksharally_ui/screens/login_screen.dart';
import 'package:aksharally_ui/screens/splash_screen.dart';
import 'package:aksharally_ui/services/tts_service.dart';
import 'package:aksharally_ui/theme/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppSettings.voiceAssistanceEnabled = false;
  });

  testWidgets(
    'does not welcome automatically and keeps sign-in narration behind the toggle',
    (tester) async {
      final engine = _LoginTtsEngine();
      final service = TTSService(engine: engine);

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            authFlow: _NoopAuthFlow(),
            ttsService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(engine.spoken, isEmpty);
      expect(find.text('Replay welcome message'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('email-field')),
        'reader@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('password-field')),
        'private-password',
      );
      await tester.tap(find.byKey(const ValueKey('voice-assistant-toggle')));
      await tester.pumpAndSettle();

      expect(engine.spoken, hasLength(1));
      expect(engine.spoken.single, contains('Sign in with your email'));
      expect(engine.spoken.single, contains('Email field'));
      expect(engine.spoken.single, contains('Continue with Google'));
      expect(engine.spoken.single, isNot(contains('reader@example.com')));
      expect(engine.spoken.single, isNot(contains('private-password')));
      expect(engine.language, 'en-IN');

      await tester.tap(find.byKey(const ValueKey('login-mode-register')));
      await tester.pumpAndSettle();
      expect(engine.spoken, hasLength(2));
      expect(engine.spoken.last, contains('Create Account'));
      expect(engine.spoken.last, contains('Register button'));
      expect(engine.spoken.last, isNot(contains(SplashScreen.welcomeMessage)));
    },
  );

  testWidgets('uses the available English fallback for sign-in narration', (
    tester,
  ) async {
    final engine = _LoginTtsEngine(availableLocales: {'en-US'});
    final service = TTSService(engine: engine);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          authFlow: _NoopAuthFlow(),
          ttsService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('voice-assistant-toggle')));
    await tester.pumpAndSettle();

    expect(engine.spoken, hasLength(1));
    expect(engine.language, 'en-US');
    expect(
      find.text('Preferred locale en-IN is unavailable; using en-US.'),
      findsOneWidget,
    );
  });

  testWidgets('does not narrate after the screen closes during initialization', (
    tester,
  ) async {
    AppSettings.voiceAssistanceEnabled = true;
    final engine = _LoginTtsEngine();
    final availability = Completer<bool>();
    engine.availabilityGate = availability;
    final service = TTSService(engine: engine);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          authFlow: _NoopAuthFlow(),
          ttsService: service,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());

    availability.complete(true);
    await tester.pump();
    await tester.pump();

    expect(engine.spoken, isEmpty);
  });
}

class _NoopAuthFlow implements AuthFlow {
  @override
  String? get currentUserId => null;

  @override
  Future<String?> register(String email, String password) async => null;

  @override
  Future<String?> login(String email, String password) async => null;

  @override
  Future<String?> signInWithGoogle() async => null;

  @override
  Future<String?> signInWithApple() async => null;
}

class _LoginTtsEngine implements TtsEngine {
  _LoginTtsEngine({Set<String>? availableLocales})
      : availableLocales =
            availableLocales ?? {'en-IN', 'en-US', 'hi-IN', 'mr-IN'};

  final Set<String> availableLocales;
  final List<String> spoken = [];
  Completer<bool>? availabilityGate;
  String? language;
  int stopCount = 0;
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
  Future<void> clearVoice() async {}

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
  Future<void> stop() async {
    stopCount++;
  }

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
