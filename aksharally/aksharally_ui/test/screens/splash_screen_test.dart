import 'package:aksharally_ui/screens/splash_screen.dart';
import 'package:aksharally_ui/services/auth_flow.dart';
import 'package:aksharally_ui/services/onboarding_storage.dart';
import 'package:aksharally_ui/services/tts_service.dart';
import 'package:aksharally_ui/services/user_profile_service.dart';
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

  testWidgets('splash plays the welcome once when voice assistance is enabled', (
    tester,
  ) async {
    AppSettings.voiceAssistanceEnabled = true;
    final engine = _SplashTtsEngine();
    final store = _MemoryAccountStore();

    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          authFlow: _FakeAuthFlow(),
          accountStore: store,
          ttsService: TTSService(engine: engine),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(engine.spoken, [SplashScreen.welcomeMessage]);
    expect(engine.language, 'en-IN');
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('signed-in user preferences load before splash welcome and Home', (
    tester,
  ) async {
    final completed = OnboardingProfile.initial(fullName: 'Mira').copyWith(
      currentStep: 4,
      completed: true,
      voiceAssistance: true,
    );
    final store = _MemoryAccountStore()
      ..documents['returning-user'] = {
        'onboardingCompleted': true,
        'onboarding': completed.toJson(),
      };
    final engine = _SplashTtsEngine();

    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          authFlow: _FakeAuthFlow('returning-user'),
          accountStore: store,
          ttsService: TTSService(engine: engine),
        ),
        onGenerateRoute: (settings) {
          if (settings.name != '/home') return null;
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('HOME')),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(engine.spoken, [SplashScreen.welcomeMessage]);
    expect(engine.language, 'en-IN');
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('leaving splash stops an unfinished welcome utterance', (
    tester,
  ) async {
    AppSettings.voiceAssistanceEnabled = true;
    final engine = _SplashTtsEngine(completeAutomatically: false);

    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          authFlow: _FakeAuthFlow(),
          accountStore: _MemoryAccountStore(),
          ttsService: TTSService(engine: engine),
        ),
        onGenerateRoute: (settings) {
          if (settings.name != '/login') return null;
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('LOGIN')),
          );
        },
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(engine.spoken, [SplashScreen.welcomeMessage]);
    expect(engine.stopCount, 1);
    expect(find.text('LOGIN'), findsOneWidget);
  });
}

class _FakeAuthFlow implements AuthFlow {
  _FakeAuthFlow([this.currentUserId]);

  @override
  final String? currentUserId;

  @override
  Future<String?> register(String email, String password) async => null;

  @override
  Future<String?> login(String email, String password) async => null;

  @override
  Future<String?> signInWithGoogle() async => null;

  @override
  Future<String?> signInWithApple() async => null;
}

class _MemoryAccountStore implements OnboardingAccountStore {
  final Map<String, Map<String, dynamic>> documents = {};

  @override
  Future<Map<String, dynamic>> load(String uid) async =>
      documents[uid] ?? <String, dynamic>{};

  @override
  Future<void> saveOnboarding(String uid, OnboardingProfile profile) async {
    documents[uid] = {
      'onboardingCompleted': profile.completed,
      'onboarding': profile.toJson(),
    };
  }
}

class _SplashTtsEngine implements TtsEngine {
  _SplashTtsEngine({this.completeAutomatically = true});

  final bool completeAutomatically;
  final List<String> spoken = [];
  String? language;
  int stopCount = 0;
  void Function()? _start;
  void Function()? _complete;

  @override
  Future<bool> isLanguageAvailable(String locale) async => true;

  @override
  Future<List<Map<String, dynamic>>> getVoices() async => [
        {'name': 'Indian English', 'locale': 'en-IN'},
      ];

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
    if (completeAutomatically) _complete?.call();
  }

  @override
  Future<bool> pause() async => true;

  @override
  Future<void> stop() async {
    stopCount++;
  }

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
