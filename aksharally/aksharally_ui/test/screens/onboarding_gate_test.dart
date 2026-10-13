import 'package:aksharally_ui/screens/home_screen.dart';
import 'package:aksharally_ui/screens/onboarding_gate.dart';
import 'package:aksharally_ui/services/auth_flow.dart';
import 'package:aksharally_ui/services/onboarding_storage.dart';
import 'package:aksharally_ui/services/user_profile_service.dart';
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
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('onboarding-step-0')), findsOneWidget);
    expect(find.text('About you'), findsOneWidget);
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
        home: OnboardingGate(uid: 'returning-reader', accountStore: store),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
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

class _FakeAuthFlow implements AuthFlow {
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
