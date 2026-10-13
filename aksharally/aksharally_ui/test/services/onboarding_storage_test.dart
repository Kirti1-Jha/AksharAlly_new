import 'package:aksharally_ui/services/onboarding_storage.dart';
import 'package:aksharally_ui/theme/accessibility_settings.dart';
import 'package:aksharally_ui/theme/app_settings.dart';
import 'package:aksharally_ui/theme/ui_accessibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OnboardingStorage storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = OnboardingStorage();
  });

  test('saves and loads an incomplete profile with its resume step', () async {
    final profile = OnboardingProfile.initial(
      fullName: 'Mira',
      currentStep: 2,
    ).copyWith(
      readingChallenges: ['crowded_text'],
      preferredLanguages: ['en', 'hi'],
      defaultReadingLanguage: 'hi',
    );

    await storage.save('user-1', profile);
    final restored = await storage.load('user-1');

    expect(restored?.fullName, 'Mira');
    expect(restored?.currentStep, 2);
    expect(restored?.completed, isFalse);
    expect(restored?.readingChallenges, ['crowded_text']);
    expect(restored?.preferredLanguages, ['en', 'hi']);
    expect(restored?.defaultReadingLanguage, 'hi');
  });

  test('applies saved reading and accessibility preferences', () async {
    final profile = OnboardingProfile.initial(fullName: 'Mira').copyWith(
      preferredLanguages: ['en', 'hi'],
      defaultReadingLanguage: 'hi',
      interfaceLanguage: 'hi',
      fontFamily: 'Lexend',
      fontSize: 28,
      letterSpacing: 1.5,
      wordSpacing: 6,
      lineHeight: 2,
      colorTheme: 'pale_blue_navy',
      wordHighlighting: true,
      readingHighlight: false,
      focusLineMode: true,
      readingRuler: true,
      syllableBreakdown: true,
      voiceAssistance: true,
      voiceLanguage: 'hi',
      speechRate: 0.7,
      largerControls: true,
      highContrast: true,
      reduceMotion: true,
      simplifyText: true,
    );
    await storage.save('user-1', profile);
    final restored = await storage.load('user-1');

    await storage.applyReadingPreferences(restored!);

    expect(AccessibilitySettings.fontFamily, 'Lexend');
    expect(AccessibilitySettings.fontSize, 28);
    expect(AccessibilitySettings.letterSpacing, 1.5);
    expect(AccessibilitySettings.wordSpacing, 6);
    expect(AccessibilitySettings.lineHeight, 2);
    expect(AccessibilitySettings.colorTheme, 'pale_blue_navy');
    expect(AccessibilitySettings.wordHighlighting, isFalse);
    expect(AccessibilitySettings.focusLineMode, isTrue);
    expect(AccessibilitySettings.readingRuler, isTrue);
    expect(AccessibilitySettings.syllableBreakdown, isTrue);
    expect(UIAccessibility.fontFamily, 'Lexend');
    expect(UIAccessibility.highContrastEnabled, isTrue);
    expect(UIAccessibility.largeTouchTargetsEnabled, isTrue);
    expect(UIAccessibility.reducedAnimationsEnabled, isTrue);
    expect(AppSettings.language, 'hi');
    expect(AppSettings.interfaceLanguage, 'hi');
    expect(AppSettings.voiceAssistanceEnabled, isTrue);
    expect(AppSettings.voiceLanguage, 'hi');
    expect(AppSettings.speechRate, 0.7);
    expect(AppSettings.autoSimplifyText, isTrue);
  });
}
