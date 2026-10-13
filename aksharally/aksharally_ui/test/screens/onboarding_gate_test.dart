import 'package:aksharally_ui/screens/home_screen.dart';
import 'package:aksharally_ui/screens/onboarding_gate.dart';
import 'package:aksharally_ui/screens/onboarding_screen.dart';
import 'package:aksharally_ui/services/onboarding_storage.dart';
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

  testWidgets(
    'resumes an incomplete profile at its saved step',
    (tester) async {
      await storage.save(
        'user-1',
        OnboardingProfile.initial(fullName: 'Mira', currentStep: 2).copyWith(
          readingChallenges: ['crowded_text'],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingGate(
            uid: 'user-1',
            storage: storage,
            accountStore: accountStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Step 3 of 5'), findsOneWidget);
      expect(find.text('Reading appearance'), findsOneWidget);
    },
  );

  testWidgets('routes a completed profile to Home', (tester) async {
    await storage.save(
      'user-1',
      OnboardingProfile.initial(fullName: 'Mira').copyWith(
        completed: true,
        currentStep: 4,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingGate(
          uid: 'user-1',
          storage: storage,
          accountStore: accountStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(accountStore.profiles['user-1']?['onboardingCompleted'], isTrue);
  });

  testWidgets('remote completion skips onboarding without a local flag', (
    tester,
  ) async {
    final complete = OnboardingProfile.initial(fullName: 'Mira').copyWith(
      completed: true,
      currentStep: 4,
      voiceAssistance: true,
    );
    accountStore.profiles['user-2'] = {
      'fullName': complete.fullName,
      'onboardingCompleted': true,
      'onboarding': complete.toJson(),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingGate(
          uid: 'user-2',
          storage: storage,
          accountStore: accountStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('a remote incomplete status reopens onboarding', (tester) async {
    await storage.save(
      'user-3',
      OnboardingProfile.initial(fullName: 'Mira').copyWith(
        completed: true,
        currentStep: 4,
      ),
    );
    accountStore.profiles['user-3'] = {'onboardingCompleted': false};

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingGate(
          uid: 'user-3',
          storage: storage,
          accountStore: accountStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text('Step 5 of 5'), findsOneWidget);
  });

  testWidgets('an incomplete remote draft is not overridden by a local completion', (
    tester,
  ) async {
    await storage.save(
      'user-4',
      OnboardingProfile.initial(fullName: 'Local copy').copyWith(
        completed: true,
        currentStep: 4,
      ),
    );
    final remoteDraft =
        OnboardingProfile.initial(fullName: 'Remote copy', currentStep: 2);
    accountStore.profiles['user-4'] = {
      'onboarding': remoteDraft.toJson(),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingGate(
          uid: 'user-4',
          storage: storage,
          accountStore: accountStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text('Step 3 of 5'), findsOneWidget);
    expect(accountStore.profiles['user-4']?['onboardingCompleted'], isNull);
  });

  testWidgets('account profile errors show retry instead of returning to login', (
    tester,
  ) async {
    accountStore.failingUid = 'user-5';

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingGate(
          uid: 'user-5',
          storage: storage,
          accountStore: accountStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets(
    'clears malformed saved data and starts onboarding safely',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'aksharally.onboarding.v1.user-1': '{not valid json',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingGate(
            uid: 'user-1',
            storage: storage,
            accountStore: accountStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Step 1 of 5'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('aksharally.onboarding.v1.user-1'), isNull);
    },
  );

  testWidgets('does not offer unsupported spoken navigation', (tester) async {
    await storage.save(
      'user-1',
      OnboardingProfile.initial(fullName: 'Mira', currentStep: 3),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingGate(
          uid: 'user-1',
          storage: storage,
          accountStore: accountStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Step 4 of 5'), findsOneWidget);
    expect(find.text('Spoken instructions and navigation'), findsNothing);
  });
}

class _MemoryAccountStore implements OnboardingAccountStore {
  final Map<String, Map<String, dynamic>> profiles = {};
  String? failingUid;

  @override
  Future<Map<String, dynamic>> load(String uid) async {
    if (uid == failingUid) throw StateError('test account store failure');
    return profiles[uid] ?? <String, dynamic>{};
  }

  @override
  Future<void> saveOnboarding(String uid, OnboardingProfile profile) async {
    profiles[uid] = {
      'fullName': profile.fullName,
      'preferredLanguage': profile.defaultReadingLanguage,
      'onboardingCompleted': profile.completed,
      'onboarding': profile.toJson(),
    };
  }
}
