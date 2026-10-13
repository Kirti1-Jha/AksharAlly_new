import 'package:aksharally_ui/screens/onboarding_screen.dart';
import 'package:aksharally_ui/services/onboarding_storage.dart';
import 'package:aksharally_ui/services/user_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OnboardingStorage storage;
  late _MemoryAccountStore accountStore;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = OnboardingStorage();
    accountStore = _MemoryAccountStore();
  });

  testWidgets('Finish stays visible above the system safe area on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(_onboardingApp(storage, accountStore));
    await tester.pumpAndSettle();

    final finish = find.byKey(const ValueKey('onboarding-finish'));
    expect(finish, findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
    final rect = tester.getRect(finish);
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(456));
    expect(tester.widget<FilledButton>(finish).onPressed, isNotNull);
  });

  testWidgets('Finish saves answers and account completion before opening Home', (
    tester,
  ) async {
    await tester.pumpWidget(_onboardingApp(storage, accountStore));
    await tester.pumpAndSettle();

    final finish = find.byKey(const ValueKey('onboarding-finish'));
    await tester.tap(finish);
    await tester.tap(finish);
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
    expect(accountStore.saveCount, 1);
    expect(accountStore.documents['user-1']?['onboardingCompleted'], isTrue);
    final saved = accountStore.documents['user-1']?['onboarding'];
    expect(saved?['fullName'], 'Mira');
    expect(saved?['fontSize'], 27.0);
    expect(saved?['voiceAssistance'], isTrue);
    expect((await storage.load('user-1'))?.completed, isTrue);
  });
}

Widget _onboardingApp(
  OnboardingStorage storage,
  OnboardingAccountStore accountStore,
) =>
    MaterialApp(
      home: OnboardingScreen(
        uid: 'user-1',
        initialProfile: OnboardingProfile.initial(
          fullName: 'Mira',
          currentStep: 4,
        ).copyWith(
          fontSize: 27,
          voiceAssistance: true,
        ),
        storage: storage,
        accountStore: accountStore,
      ),
      routes: {
        '/home': (_) => const Scaffold(body: Center(child: Text('HOME'))),
      },
    );

class _MemoryAccountStore implements OnboardingAccountStore {
  final Map<String, Map<String, dynamic>> documents = {};
  int saveCount = 0;

  @override
  Future<Map<String, dynamic>> load(String uid) async =>
      documents[uid] ?? <String, dynamic>{};

  @override
  Future<void> saveOnboarding(String uid, OnboardingProfile profile) async {
    saveCount++;
    documents[uid] = {
      'fullName': profile.fullName,
      'preferredLanguage': profile.defaultReadingLanguage,
      'onboardingCompleted': profile.completed,
      'onboarding': profile.toJson(),
    };
  }
}
