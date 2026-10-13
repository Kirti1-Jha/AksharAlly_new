import 'package:aksharally_ui/screens/home_screen.dart';
import 'package:aksharally_ui/screens/login_screen.dart';
import 'package:aksharally_ui/screens/onboarding_gate.dart';
import 'package:aksharally_ui/services/auth_flow.dart';
import 'package:aksharally_ui/services/onboarding_storage.dart';
import 'package:aksharally_ui/services/user_profile_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('unauthenticated visitors are sent to login', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: OnboardingGate(uid: null, authFlow: _FakeAuthFlow())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.byKey(const ValueKey('email-field')), findsOneWidget);
  });

  testWidgets('new accounts are sent into onboarding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingGate(
          uid: 'new-reader',
          accountStore: _MemoryAccountStore(),
          authFlow: _FakeAuthFlow(authenticatedUid: 'new-reader'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('onboarding-step-0')), findsOneWidget);
    expect(find.text('About you'), findsOneWidget);
  });

  testWidgets('new account setup saves a default reading profile', (
    tester,
  ) async {
    final store = _MemoryAccountStore();

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingGate(
          uid: 'new-reader',
          accountStore: store,
          authFlow: _FakeAuthFlow(authenticatedUid: 'new-reader'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final account = store.documents['new-reader']!;
    expect(account['onboardingCompleted'], isFalse);
    expect(account['onboarding'], isA<Map<String, dynamic>>());
    expect(
      (account['onboarding'] as Map<String, dynamic>)['fullName'],
      isEmpty,
    );
    expect(find.byKey(const ValueKey('onboarding-step-0')), findsOneWidget);
  });

  testWidgets('completed account profiles go to the home screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profile = OnboardingProfile.initial(
      fullName: 'Mira',
    ).copyWith(currentStep: 4, completed: true);
    final store = _MemoryAccountStore()
      ..documents['returning-reader'] = {
        'onboardingCompleted': true,
        'onboarding': profile.toJson(),
      };

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingGate(
          uid: 'returning-reader',
          accountStore: store,
          authFlow: _FakeAuthFlow(authenticatedUid: 'returning-reader'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('cached saved profile is used when Firestore is unavailable', (
    tester,
  ) async {
    const uid = 'cached-reader';
    final profile = OnboardingProfile.initial(
      fullName: 'Mira',
    ).copyWith(currentStep: 4, completed: true);
    await OnboardingStorage().save(uid, profile);
    final store = _FailingAccountStore()
      ..error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingGate(
          uid: uid,
          accountStore: store,
          authFlow: _FakeAuthFlow(authenticatedUid: uid),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Retry reloads the profile without stacking another gate', (
    tester,
  ) async {
    const uid = 'retry-reader';
    final store = _FailingAccountStore()
      ..error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingGate(
          uid: uid,
          accountStore: store,
          authFlow: _FakeAuthFlow(authenticatedUid: uid),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Your reading profile could not be loaded. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);

    store.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('onboarding-step-0')), findsOneWidget);
    expect(store.loadCount, 2);
  });

  testWidgets('registration navigates to onboarding with a saved default', (
    tester,
  ) async {
    const uid = 'new-reader';
    final store = _MemoryAccountStore();
    final auth = _FakeAuthFlow(registeredUid: uid);
    await tester.pumpWidget(_loginApp(auth, store));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('login-mode-register')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('email-field')),
      'new-reader@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      'secure-passphrase',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('auth-submit')));
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();

    expect(auth.registerCalls, 1);
    expect(find.byKey(const ValueKey('onboarding-step-0')), findsOneWidget);
    expect(store.documents[uid]?['onboardingCompleted'], isFalse);
  });

  testWidgets('existing-user login opens home with the saved profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const uid = 'returning-reader';
    final profile = OnboardingProfile.initial(
      fullName: 'Mira',
    ).copyWith(currentStep: 4, completed: true);
    final store = _MemoryAccountStore()
      ..documents[uid] = {
        'onboardingCompleted': true,
        'onboarding': profile.toJson(),
      };
    final auth = _FakeAuthFlow(loggedInUid: uid);
    await tester.pumpWidget(_loginApp(auth, store));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('email-field')),
      'mira@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      'secure-passphrase',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('auth-submit')));
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();

    expect(auth.loginCalls, 1);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}

Widget _loginApp(_FakeAuthFlow auth, _MemoryAccountStore store) {
  return MaterialApp(
    home: LoginScreen(authFlow: auth),
    onGenerateRoute: (settings) {
      if (settings.name != '/home') return null;
      final uid = settings.arguments as String?;
      return MaterialPageRoute<void>(
        builder: (_) => OnboardingGate(
          uid: uid,
          accountStore: store,
          authFlow: auth,
        ),
      );
    },
  );
}

class _MemoryAccountStore implements OnboardingAccountStore {
  final Map<String, Map<String, dynamic>> documents = {};
  int loadCount = 0;

  @override
  Future<Map<String, dynamic>> load(String uid) async {
    loadCount += 1;
    return documents[uid] ?? <String, dynamic>{};
  }

  @override
  Future<void> saveOnboarding(String uid, OnboardingProfile profile) async {
    documents[uid] = {
      'onboardingCompleted': profile.completed,
      'onboarding': profile.toJson(),
    };
  }
}

class _FailingAccountStore extends _MemoryAccountStore {
  FirebaseException? error;

  @override
  Future<Map<String, dynamic>> load(String uid) async {
    loadCount += 1;
    final currentError = error;
    if (currentError != null) throw currentError;
    return documents[uid] ?? <String, dynamic>{};
  }
}

class _FakeAuthFlow implements AuthFlow {
  _FakeAuthFlow({
    String? authenticatedUid,
    this.registeredUid,
    this.loggedInUid,
  }) : _currentUserId = authenticatedUid;

  final String? registeredUid;
  final String? loggedInUid;
  String? _currentUserId;
  int registerCalls = 0;
  int loginCalls = 0;

  @override
  String? get currentUserId => _currentUserId;

  @override
  Future<String?> register(String email, String password) async {
    registerCalls += 1;
    _currentUserId = registeredUid;
    return registeredUid;
  }

  @override
  Future<String?> login(String email, String password) async {
    loginCalls += 1;
    _currentUserId = loggedInUid;
    return loggedInUid;
  }

  @override
  Future<String?> signInWithGoogle() async => null;

  @override
  Future<String?> signInWithApple() async => null;
}
