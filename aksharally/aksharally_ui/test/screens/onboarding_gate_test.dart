import 'package:aksharally_ui/screens/home_screen.dart';
import 'package:aksharally_ui/screens/login_screen.dart';
import 'package:aksharally_ui/screens/onboarding_gate.dart';
import 'package:aksharally_ui/screens/onboarding_screen.dart';
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
          isNewUser: true,
          accountStore: _MemoryAccountStore(),
          authFlow: _FakeAuthFlow(authenticatedUid: 'new-reader'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('onboarding-step-0')), findsOneWidget);
    expect(find.text('Your preferences'), findsOneWidget);
  });

  testWidgets('two-question pages preserve answers and restore progress', (
    tester,
  ) async {
    const uid = 'paired-question-reader';
    final storage = OnboardingStorage();
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          uid: uid,
          initialProfile: OnboardingProfile.initial(fullName: 'Mira'),
          storage: storage,
          accountStore: _MemoryAccountStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 6'), findsOneWidget);
    expect(find.text('What should we call you?'), findsOneWidget);
    expect(find.text('Age group (optional)'), findsOneWidget);
    expect(find.text('Interface language'), findsNothing);

    await tester.ensureVisible(find.text('18–24'));
    await tester.tap(find.text('18–24'));
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 6'), findsOneWidget);
    expect(find.text('Who are you reading for?'), findsOneWidget);
    expect(find.text('How comfortable does reading feel?'), findsOneWidget);
    final saved = await storage.load(uid);
    expect(saved?.currentStep, 1);
    expect(saved?.ageGroup, '18_24');

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          uid: uid,
          initialProfile: saved!,
          storage: storage,
          accountStore: _MemoryAccountStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 6'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 6'), findsOneWidget);
    expect(
      tester
          .widget<FilterChip>(
            find.ancestor(
              of: find.text('18–24'),
              matching: find.byType(FilterChip),
            ),
          )
          .selected,
      isTrue,
    );
  });

  testWidgets('new account setup saves a default reading profile', (
    tester,
  ) async {
    final store = _MemoryAccountStore();

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingGate(
          uid: 'new-reader',
          isNewUser: true,
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

  testWidgets('returning account with no onboarding record goes to home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const uid = 'legacy-reader';
    final store = _MemoryAccountStore();
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
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(store.documents, isEmpty);
  });

  testWidgets('newer local onboarding draft wins over an older Firestore draft', (
    tester,
  ) async {
    const uid = 'draft-reader';
    final localDraft = OnboardingProfile.initial(
      fullName: 'Local draft',
      currentStep: 3,
    ).copyWith(updatedAt: 200, preferredLanguages: ['hi']);
    final remoteDraft = OnboardingProfile.initial(
      fullName: 'Older remote draft',
      currentStep: 1,
    ).copyWith(updatedAt: 100);
    final storage = OnboardingStorage();
    await storage.save(uid, localDraft);
    final store = _MemoryAccountStore()
      ..documents[uid] = {
        'onboardingCompleted': false,
        'onboarding': remoteDraft.toJson(),
      };

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingGate(
          uid: uid,
          storage: storage,
          accountStore: store,
          authFlow: _FakeAuthFlow(authenticatedUid: uid),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('onboarding-step-3')), findsOneWidget);
    expect((await storage.load(uid))?.fullName, 'Local draft');
    expect(
      (store.documents[uid]!['onboarding'] as Map<String, dynamic>)['fullName'],
      'Local draft',
    );
  });

  testWidgets('newer Firestore onboarding draft wins over an older local draft', (
    tester,
  ) async {
    const uid = 'remote-draft-reader';
    final localDraft = OnboardingProfile.initial(
      fullName: 'Older local draft',
      currentStep: 1,
    ).copyWith(updatedAt: 100);
    final remoteDraft = OnboardingProfile.initial(
      fullName: 'Remote draft',
      currentStep: 2,
    ).copyWith(updatedAt: 200, preferredLanguages: ['mr']);
    final storage = OnboardingStorage();
    await storage.save(uid, localDraft);
    final store = _MemoryAccountStore()
      ..documents[uid] = {
        'onboardingCompleted': false,
        'onboarding': remoteDraft.toJson(),
      };

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingGate(
          uid: uid,
          storage: storage,
          accountStore: store,
          authFlow: _FakeAuthFlow(authenticatedUid: uid),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('onboarding-step-2')), findsOneWidget);
    expect((await storage.load(uid))?.fullName, 'Remote draft');
    expect((await storage.load(uid))?.preferredLanguages, ['mr']);
  });

  testWidgets('a different UID never receives another account local draft', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = OnboardingStorage();
    await storage.save(
      'other-reader',
      OnboardingProfile.initial(
        fullName: 'Other user',
        currentStep: 2,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingGate(
          uid: 'current-reader',
          storage: storage,
          accountStore: _MemoryAccountStore(),
          authFlow: _FakeAuthFlow(authenticatedUid: 'current-reader'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets(
    'completed account with missing optional profile fields opens home',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 960);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const uid = 'partial-reader';
      final store = _MemoryAccountStore()
        ..documents[uid] = {
          'onboardingCompleted': true,
          'fullName': 'Mira',
          'preferredLanguage': 'mr',
          'ageGroup': '25_44',
          // Older profiles may omit most nested fields, including completed.
          'onboarding': <String, dynamic>{'fontFamily': 'Lexend'},
        };

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

      final cached = await OnboardingStorage().load(uid);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(cached?.completed, isTrue);
      expect(cached?.currentStep, 4);
      expect(cached?.fullName, 'Mira');
      expect(cached?.preferredLanguages, ['mr']);
      expect(cached?.defaultReadingLanguage, 'mr');
      expect(cached?.ageGroup, '25_44');
      expect(cached?.fontSize, OnboardingProfile.initial().fontSize);
    },
  );

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

  testWidgets(
    'new account can begin onboarding when Firestore is temporarily unavailable',
    (tester) async {
      const uid = 'offline-new-reader';
      final store = _FailingAccountStore()
        ..error = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        );

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingGate(
            uid: uid,
            isNewUser: true,
            accountStore: store,
            authFlow: _FakeAuthFlow(authenticatedUid: uid),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('onboarding-step-0')), findsOneWidget);
      expect((await OnboardingStorage().load(uid))?.completed, isFalse);
    },
  );

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

  testWidgets('existing Google account without preferences opens home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const uid = 'google-returning-reader';
    final store = _MemoryAccountStore();
    final auth = _FakeAuthFlow(googleUid: uid);
    await tester.pumpWidget(_loginApp(auth, store));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('sign-in-google')));
    await tester.tap(find.byKey(const ValueKey('sign-in-google')));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(store.documents, isEmpty);
  });

  testWidgets('first-time Google account enters preferences', (tester) async {
    const uid = 'google-new-reader';
    final store = _MemoryAccountStore();
    final auth = _FakeAuthFlow(googleUid: uid, googleIsNewUser: true);
    await tester.pumpWidget(_loginApp(auth, store));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('sign-in-google')));
    await tester.tap(find.byKey(const ValueKey('sign-in-google')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('onboarding-step-0')), findsOneWidget);
    expect(store.documents[uid]?['onboardingCompleted'], isFalse);
  });

  testWidgets('Finish saves selected preferences before navigating home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const uid = 'finished-reader';
    final store = _MemoryAccountStore();
    final selected = OnboardingProfile.initial(fullName: 'Mira').copyWith(
      currentStep: 7,
      preferredLanguages: ['hi', 'mr'],
      defaultReadingLanguage: 'mr',
      ageGroup: '25_44',
      fontSize: 28,
      letterSpacing: 1.5,
      wordSpacing: 6,
      lineHeight: 2.1,
      colorTheme: 'pale_blue_navy',
      focusLineMode: true,
      readingRuler: true,
      syllableBreakdown: true,
      simplifyText: true,
      voiceAssistance: true,
      voiceLanguage: 'hi',
      speechRate: 0.7,
      highContrast: true,
      reduceMotion: true,
      readingGoals: ['understanding'],
      materialTypes: ['books'],
      dailyTargetMinutes: 30,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          uid: uid,
          initialProfile: selected,
          storage: OnboardingStorage(),
          accountStore: store,
        ),
        routes: {'/home': (_) => const Scaffold(body: Text('Home reached'))},
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('onboarding-finish')));
    await tester.pumpAndSettle();

    final saved = store.documents[uid]!;
    final savedProfile = saved['onboarding'] as Map<String, dynamic>;
    expect(find.text('Home reached'), findsOneWidget);
    expect(saved['onboardingCompleted'], isTrue);
    expect(
      savedProfile.keys,
      containsAll(OnboardingProfile.initial().toJson().keys),
    );
    expect(savedProfile['preferredLanguages'], ['hi', 'mr']);
    expect(savedProfile['defaultReadingLanguage'], 'mr');
    expect(savedProfile['fontSize'], 28);
    expect(savedProfile['colorTheme'], 'pale_blue_navy');
    expect(savedProfile['voiceAssistance'], isTrue);
    expect(savedProfile['speechRate'], 0.7);
    expect(savedProfile['dailyTargetMinutes'], 30);
  });

  testWidgets('profile save failure keeps onboarding open with debug detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const uid = 'save-failure-reader';
    final store = _MemoryAccountStore()
      ..saveError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions.',
      );
    final profile = OnboardingProfile.initial(
      fullName: 'Mira',
    ).copyWith(currentStep: 7);

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          uid: uid,
          initialProfile: profile,
          storage: OnboardingStorage(),
          accountStore: store,
        ),
        routes: {'/home': (_) => const Scaffold(body: Text('Home reached'))},
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('onboarding-finish')));
    await tester.pumpAndSettle();

    expect(find.text('Home reached'), findsNothing);
    expect(
      find.text('Your profile could not be saved. Please try again.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('cloud_firestore/permission-denied'),
      findsOneWidget,
    );
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
      final arguments = settings.arguments;
      final authResult = arguments is AuthFlowResult ? arguments : null;
      final uid = authResult?.uid ?? (arguments is String ? arguments : null);
      return MaterialPageRoute<void>(
        builder: (_) => OnboardingGate(
          uid: uid,
          isNewUser: authResult?.isNewUser ?? false,
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
  FirebaseException? saveError;

  @override
  Future<Map<String, dynamic>> load(String uid) async {
    loadCount += 1;
    return documents[uid] ?? <String, dynamic>{};
  }

  @override
  Future<void> saveOnboarding(String uid, OnboardingProfile profile) async {
    final currentError = saveError;
    if (currentError != null) throw currentError;
    documents[uid] = {
      'fullName': profile.fullName,
      'preferredLanguage': profile.defaultReadingLanguage,
      'ageGroup': profile.ageGroup,
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
    this.googleUid,
    this.googleIsNewUser = false,
  }) : _currentUserId = authenticatedUid;

  final String? registeredUid;
  final String? loggedInUid;
  final String? googleUid;
  final bool googleIsNewUser;
  String? _currentUserId;
  int registerCalls = 0;
  int loginCalls = 0;

  @override
  String? get currentUserId => _currentUserId;

  @override
  Future<AuthFlowResult?> register(String email, String password) async {
    registerCalls += 1;
    _currentUserId = registeredUid;
    return registeredUid == null
        ? null
        : AuthFlowResult(uid: registeredUid!, isNewUser: true);
  }

  @override
  Future<AuthFlowResult?> login(String email, String password) async {
    loginCalls += 1;
    _currentUserId = loggedInUid;
    return loggedInUid == null
        ? null
        : AuthFlowResult(uid: loggedInUid!, isNewUser: false);
  }

  @override
  Future<AuthFlowResult?> signInWithGoogle() async {
    _currentUserId = googleUid;
    return googleUid == null
        ? null
        : AuthFlowResult(uid: googleUid!, isNewUser: googleIsNewUser);
  }

  @override
  Future<AuthFlowResult?> signInWithApple() async => null;
}
