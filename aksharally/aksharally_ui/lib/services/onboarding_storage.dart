import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../theme/accessibility_settings.dart';

class OnboardingProfile {
  const OnboardingProfile({
    required this.fullName,
    required this.preferredLanguages,
    required this.fontFamily,
    required this.fontSize,
    required this.letterSpacing,
    required this.wordSpacing,
    required this.lineHeight,
    required this.colorTheme,
    required this.wordHighlighting,
    required this.focusLineMode,
    required this.readingRuler,
    required this.syllableBreakdown,
    required this.currentStep,
    required this.completed,
  });

  factory OnboardingProfile.initial({
    String fullName = '',
    int currentStep = 0,
  }) => OnboardingProfile(
    fullName: fullName,
    preferredLanguages: const ['en'],
    fontFamily: 'Lexend',
    fontSize: 22,
    letterSpacing: 1,
    wordSpacing: 4,
    lineHeight: 1.8,
    colorTheme: 'soft_yellow_black',
    wordHighlighting: true,
    focusLineMode: false,
    readingRuler: false,
    syllableBreakdown: false,
    currentStep: currentStep,
    completed: false,
  );

  factory OnboardingProfile.fromJson(Map<String, dynamic> json) {
    final defaults = OnboardingProfile.initial();
    return OnboardingProfile(
      fullName: json['fullName'] as String? ?? '',
      preferredLanguages: List<String>.from(
        json['preferredLanguages'] as List? ?? defaults.preferredLanguages,
      ),
      fontFamily: json['fontFamily'] as String? ?? defaults.fontFamily,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? defaults.fontSize,
      letterSpacing:
          (json['letterSpacing'] as num?)?.toDouble() ?? defaults.letterSpacing,
      wordSpacing:
          (json['wordSpacing'] as num?)?.toDouble() ?? defaults.wordSpacing,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? defaults.lineHeight,
      colorTheme: json['colorTheme'] as String? ?? defaults.colorTheme,
      wordHighlighting:
          json['wordHighlighting'] as bool? ?? defaults.wordHighlighting,
      focusLineMode: json['focusLineMode'] as bool? ?? defaults.focusLineMode,
      readingRuler: json['readingRuler'] as bool? ?? defaults.readingRuler,
      syllableBreakdown:
          json['syllableBreakdown'] as bool? ?? defaults.syllableBreakdown,
      currentStep: json['currentStep'] as int? ?? defaults.currentStep,
      completed: json['completed'] as bool? ?? false,
    );
  }

  final String fullName;
  final List<String> preferredLanguages;
  final String fontFamily;
  final double fontSize;
  final double letterSpacing;
  final double wordSpacing;
  final double lineHeight;
  final String colorTheme;
  final bool wordHighlighting;
  final bool focusLineMode;
  final bool readingRuler;
  final bool syllableBreakdown;
  final int currentStep;
  final bool completed;

  OnboardingProfile copyWith({
    String? fullName,
    List<String>? preferredLanguages,
    String? fontFamily,
    double? fontSize,
    double? letterSpacing,
    double? wordSpacing,
    double? lineHeight,
    String? colorTheme,
    bool? wordHighlighting,
    bool? focusLineMode,
    bool? readingRuler,
    bool? syllableBreakdown,
    int? currentStep,
    bool? completed,
  }) => OnboardingProfile(
    fullName: fullName ?? this.fullName,
    preferredLanguages: preferredLanguages ?? this.preferredLanguages,
    fontFamily: fontFamily ?? this.fontFamily,
    fontSize: fontSize ?? this.fontSize,
    letterSpacing: letterSpacing ?? this.letterSpacing,
    wordSpacing: wordSpacing ?? this.wordSpacing,
    lineHeight: lineHeight ?? this.lineHeight,
    colorTheme: colorTheme ?? this.colorTheme,
    wordHighlighting: wordHighlighting ?? this.wordHighlighting,
    focusLineMode: focusLineMode ?? this.focusLineMode,
    readingRuler: readingRuler ?? this.readingRuler,
    syllableBreakdown: syllableBreakdown ?? this.syllableBreakdown,
    currentStep: currentStep ?? this.currentStep,
    completed: completed ?? this.completed,
  );

  Map<String, Object?> toJson() => {
    'fullName': fullName,
    'preferredLanguages': preferredLanguages,
    'fontFamily': fontFamily,
    'fontSize': fontSize,
    'letterSpacing': letterSpacing,
    'wordSpacing': wordSpacing,
    'lineHeight': lineHeight,
    'colorTheme': colorTheme,
    'wordHighlighting': wordHighlighting,
    'focusLineMode': focusLineMode,
    'readingRuler': readingRuler,
    'syllableBreakdown': syllableBreakdown,
    'currentStep': currentStep,
    'completed': completed,
  };
}

class OnboardingStorage {
  static const _keyPrefix = 'aksharally.onboarding.v1.';

  String _keyFor(String uid) {
    if (uid.trim().isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'A Firebase UID is required.');
    }
    return '$_keyPrefix$uid';
  }

  Future<OnboardingProfile?> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(uid));
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Saved onboarding data is invalid.');
    }
    return OnboardingProfile.fromJson(decoded);
  }

  Future<void> save(String uid, OnboardingProfile profile) async {
    if (profile.currentStep < 0 || profile.currentStep > 3) {
      throw ArgumentError.value(profile.currentStep, 'currentStep');
    }
    if (profile.completed &&
        (profile.fullName.trim().isEmpty ||
            profile.preferredLanguages.isEmpty)) {
      throw ArgumentError('Completed onboarding requires a name and language.');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(uid), jsonEncode(profile.toJson()));
  }

  Future<void> applyReadingPreferences(OnboardingProfile profile) async {
    if (!AccessibilitySettings.fonts.contains(profile.fontFamily) ||
        !AccessibilitySettings.themeLabels.containsKey(profile.colorTheme)) {
      throw const FormatException('Saved reading preferences are invalid.');
    }

    AccessibilitySettings.profile = 'customize';
    AccessibilitySettings.fontFamily = profile.fontFamily;
    AccessibilitySettings.fontSize = profile.fontSize;
    AccessibilitySettings.letterSpacing = profile.letterSpacing;
    AccessibilitySettings.wordSpacing = profile.wordSpacing;
    AccessibilitySettings.lineHeight = profile.lineHeight;
    AccessibilitySettings.colorTheme = profile.colorTheme;
    AccessibilitySettings.wordHighlighting = profile.wordHighlighting;
    AccessibilitySettings.focusLineMode = profile.focusLineMode;
    AccessibilitySettings.readingRuler = profile.readingRuler;
    AccessibilitySettings.syllableBreakdown = profile.syllableBreakdown;
    await AccessibilitySettings.save();
  }
}
