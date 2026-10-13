import 'package:aksharally_ui/screens/splash_screen.dart';
import 'package:aksharally_ui/services/tts_service.dart';
import 'package:aksharally_ui/theme/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AppSettings.voiceAssistanceEnabled = false;
  });

  testWidgets('retains the main splash design and stays quiet when disabled', (
    tester,
  ) async {
    final engine = _FakeTtsEngine();

    await tester.pumpWidget(_app(engine));
    await tester.pumpAndSettle();

    expect(find.text('AksharAlly'), findsOneWidget);
    expect(find.text('Read with confidence.'), findsOneWidget);
    expect(find.text("Let's Begin"), findsOneWidget);
    expect(find.bySemanticsLabel('AksharAlly logo'), findsOneWidget);
    expect(engine.spoken, isEmpty);
  });

  testWidgets('speaks the welcome once when voice assistance is enabled', (
    tester,
  ) async {
    AppSettings.voiceAssistanceEnabled = true;
    final engine = _FakeTtsEngine();

    await tester.pumpWidget(_app(engine));
    await tester.pumpAndSettle();

    expect(engine.spoken, [SplashScreen.welcomeMessage]);
    expect(engine.language, TTSService.preferredEnglishLocale);
  });

  testWidgets('welcome can be replayed and Begin opens login', (tester) async {
    final engine = _FakeTtsEngine();

    await tester.pumpWidget(_app(engine));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hear welcome message again'));
    await tester.pumpAndSettle();
    expect(engine.spoken, [SplashScreen.welcomeMessage]);

    await tester.tap(find.text("Let's Begin"));
    await tester.pumpAndSettle();
    expect(find.text('LOGIN'), findsOneWidget);
  });
}

Widget _app(_FakeTtsEngine engine) => MaterialApp(
  home: SplashScreen(ttsService: TTSService(engine: engine)),
  onGenerateRoute: (settings) {
    if (settings.name != '/login') return null;
    return MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('LOGIN')),
    );
  },
);

class _FakeTtsEngine implements TtsEngine {
  final List<String> spoken = [];
  String? language;
  void Function()? _start;
  void Function()? _complete;

  @override
  Future<bool> isLanguageAvailable(String locale) async => true;

  @override
  Future<List<Map<String, dynamic>>> getVoices() async => const [];

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
    _start?.call();
    _complete?.call();
  }

  @override
  Future<bool> pause() async => true;

  @override
  Future<void> stop() async {}

  @override
  void setStartHandler(void Function() callback) => _start = callback;

  @override
  void setCompletionHandler(void Function() callback) => _complete = callback;

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
