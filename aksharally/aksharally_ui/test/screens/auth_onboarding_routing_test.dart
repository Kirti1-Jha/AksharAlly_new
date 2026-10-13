import 'package:aksharally_ui/screens/home_screen.dart';
import 'package:aksharally_ui/screens/login_screen.dart';
import 'package:aksharally_ui/screens/onboarding_gate.dart';
import 'package:aksharally_ui/screens/onboarding_screen.dart';
import 'package:aksharally_ui/services/auth_flow.dart';
import 'package:aksharally_ui/services/onboarding_storage.dart';
import 'package:aksharally_ui/services/user_profile_service.dart';
import 'package:aksharally_ui/theme/app_settings.dart';
import 'package:aksharally_ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAuthFlow auth;
  late OnboardingStorage storage;
  late _MemoryAccountStore accountStore;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppSettings.voiceAssistanceEnabled = false;
    auth = _FakeAuthFlow();
    storage = OnboardingStorage();
    accountStore = _MemoryAccountStore();
  });

  testWidgets('email registration opens onboarding and completes into Home', (
    tester,
  ) async {
    await tester.pumpWidget(_routingApp(auth, storage, accountStore));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('login-mode-register')));
    await tester.enterText(
      find.byKey(const ValueKey('email-field')),
      'new-reader@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      'correct-horse-battery',
    );
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();

    expect(auth.registrationCalls, 1);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await _finishOnboarding(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      accountStore.documents['email-new']?['onboardingCompleted'],
      isTrue,
    );
  });

  testWidgets('first-time Google sign-in opens onboarding and then Home', (
    tester,
  ) async {
    await tester.pumpWidget(_routingApp(auth, storage, accountStore));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sign-in-google')));
    await tester.pumpAndSettle();

    expect(auth.googleCalls, 1);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await _finishOnboarding(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(accountStore.documents['google-new']?['onboardingCompleted'], isTrue);
  });

  testWidgets('Apple sign-in also opens the onboarding gate for a new account', (
    tester,
  ) async {
    await tester.pumpWidget(_routingApp(auth, storage, accountStore));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sign-in-apple')));
    await tester.pumpAndSettle();

    expect(auth.appleCalls, 1);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('returning account with remote completion opens Home directly', (
    tester,
  ) async {
    final completed = OnboardingProfile.initial(
      fullName: 'Returning Reader',
    ).copyWith(completed: true, currentStep: 4);
    accountStore.documents['returning-user'] = {
      'fullName': completed.fullName,
      'onboardingCompleted': true,
      'onboarding': completed.toJson(),
    };

    await tester.pumpWidget(_routingApp(auth, storage, accountStore));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('email-field')),
      'returning@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      'correct-horse-battery',
    );
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();

    expect(auth.loginCalls, 1);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('login card uses the shared theme and keeps voice controls visible', (
    tester,
  ) async {
    await tester.pumpWidget(_routingApp(auth, storage, accountStore));
    await tester.pumpAndSettle();

    expect(find.byType(Card), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
      AppTheme.background,
    );
    expect(find.byKey(const ValueKey('voice-assistant-toggle')), findsOneWidget);
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Replay welcome message'), findsNothing);
  });
}

Future<void> _finishOnboarding(WidgetTester tester) async {
  await tester.enterText(find.byKey(const ValueKey('onboarding-name')), 'Mira');
  for (var step = 0; step < 4; step++) {
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
  }
  expect(find.text('Step 5 of 5'), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('onboarding-finish')));
  await tester.pumpAndSettle();
}

Widget _routingApp(
  _FakeAuthFlow auth,
  OnboardingStorage storage,
  OnboardingAccountStore accountStore,
) =>
    MaterialApp(
      home: LoginScreen(authFlow: auth),
      onGenerateRoute: (settings) {
        if (settings.name != '/home') return null;
        final uid = settings.arguments as String? ?? auth.currentUserId;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => OnboardingGate(
            uid: uid,
            storage: storage,
            accountStore: accountStore,
          ),
        );
      },
    );

class _FakeAuthFlow implements AuthFlow {
  String? currentUserId;
  int registrationCalls = 0;
  int loginCalls = 0;
  int googleCalls = 0;
  int appleCalls = 0;

  @override
  Future<String?> register(String email, String password) async {
    registrationCalls++;
    currentUserId = 'email-new';
    return currentUserId;
  }

  @override
  Future<String?> login(String email, String password) async {
    loginCalls++;
    currentUserId = 'returning-user';
    return currentUserId;
  }

  @override
  Future<String?> signInWithGoogle() async {
    googleCalls++;
    currentUserId = 'google-new';
    return currentUserId;
  }

  @override
  Future<String?> signInWithApple() async {
    appleCalls++;
    currentUserId = 'apple-new';
    return currentUserId;
  }
}

class _MemoryAccountStore implements OnboardingAccountStore {
  final Map<String, Map<String, dynamic>> documents = {};

  @override
  Future<Map<String, dynamic>> load(String uid) async =>
      documents[uid] ?? <String, dynamic>{};

  @override
  Future<void> saveOnboarding(String uid, OnboardingProfile profile) async {
    documents[uid] = {
      'fullName': profile.fullName,
      'preferredLanguage': profile.defaultReadingLanguage,
      'onboardingCompleted': profile.completed,
      'onboarding': profile.toJson(),
    };
  }
}
