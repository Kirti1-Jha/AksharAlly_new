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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = OnboardingStorage();
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
        MaterialApp(home: OnboardingGate(uid: 'user-1', storage: storage)),
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
      MaterialApp(home: OnboardingGate(uid: 'user-1', storage: storage)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets(
    'clears malformed saved data and starts onboarding safely',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'aksharally.onboarding.v1.user-1': '{not valid json',
      });

      await tester.pumpWidget(
        MaterialApp(home: OnboardingGate(uid: 'user-1', storage: storage)),
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
      MaterialApp(home: OnboardingGate(uid: 'user-1', storage: storage)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Step 4 of 5'), findsOneWidget);
    expect(find.text('Spoken instructions and navigation'), findsNothing);
  });
}
