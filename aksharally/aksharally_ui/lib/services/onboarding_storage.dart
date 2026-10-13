import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../theme/accessibility_settings.dart';
import '../theme/app_settings.dart';
import '../theme/ui_accessibility.dart';

class OnboardingProfile {
  const OnboardingProfile({
    required this.fullName,
    required this.ageGroup,
    required this.interfaceLanguage,
    required this.readerRole,
    required this.readingComfort,
    required this.readingChallenges,
    required this.supportStatus,
    required this.preferredLanguages,
    required this.defaultReadingLanguage,
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
    required this.breakLongSentences,
    required this.simplifyText,
    required this.voiceAssistance,
    required this.voiceLanguage,
    required this.speechRate,
    required this.readingHighlight,
    required this.largerControls,
    required this.highContrast,
    required this.reduceMotion,
    required this.readingGoals,
    required this.materialTypes,
    required this.explanationStyle,
    required this.dailyTargetMinutes,
    required this.currentStep,
    required this.completed,
  });

  factory OnboardingProfile.initial({
    String fullName = '',
    int currentStep = 0,
  }) => OnboardingProfile(
    fullName: fullName,
    ageGroup: '',
    interfaceLanguage: 'en',
    readerRole: '',
    readingComfort: '',
    readingChallenges: const [],
    supportStatus: 'prefer_not_to_say',
    preferredLanguages: const ['en'],
    defaultReadingLanguage: 'en',
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
    breakLongSentences: true,
    simplifyText: false,
    voiceAssistance: false,
    voiceLanguage: 'en',
    speechRate: 0.4,
    readingHighlight: true,
    largerControls: false,
    highContrast: false,
    reduceMotion: false,
    readingGoals: const [],
    materialTypes: const [],
    explanationStyle: 'shorter_sentences',
    dailyTargetMinutes: 0,
    currentStep: currentStep,
    completed: false,
  );

  factory OnboardingProfile.fromJson(Map<String, dynamic> json) {
    final defaults = OnboardingProfile.initial();
    String stringValue(String key, String fallback) =>
        json[key] is String ? json[key] as String : fallback;
    bool boolValue(String key, bool fallback) =>
        json[key] is bool ? json[key] as bool : fallback;
    double numberValue(String key, double fallback) =>
        json[key] is num ? (json[key] as num).toDouble() : fallback;
    List<String> stringList(String key, List<String> fallback) {
      final value = json[key];
      return value is List
          ? value.whereType<String>().toList()
          : List<String>.from(fallback);
    }

    const supportedLanguages = ['en', 'hi', 'mr'];
    final languages = stringList(
      'preferredLanguages',
      defaults.preferredLanguages,
    ).where(supportedLanguages.contains).toSet().toList();
    if (languages.isEmpty) languages.add('en');
    final requestedDefault = stringValue(
      'defaultReadingLanguage',
      defaults.defaultReadingLanguage,
    );
    const supportedThemes = [
      'cream_black',
      'soft_yellow_black',
      'pale_blue_navy',
      'pale_green_gray',
      'white_black',
    ];
    final requestedFont = stringValue('fontFamily', defaults.fontFamily);
    final requestedTheme = stringValue('colorTheme', defaults.colorTheme);
    final savedStep = json['currentStep'];
    return OnboardingProfile(
      fullName: stringValue('fullName', defaults.fullName),
      ageGroup:
          const [
            'under_13',
            '13_17',
            '18_24',
            '25_44',
            '45_plus',
          ].contains(stringValue('ageGroup', defaults.ageGroup))
          ? stringValue('ageGroup', defaults.ageGroup)
          : defaults.ageGroup,
      interfaceLanguage:
          const ['en', 'hi'].contains(
            stringValue('interfaceLanguage', defaults.interfaceLanguage),
          )
          ? stringValue('interfaceLanguage', defaults.interfaceLanguage)
          : defaults.interfaceLanguage,
      readerRole:
          const [
            'self',
            'child',
            'teacher',
            'supporting',
          ].contains(stringValue('readerRole', defaults.readerRole))
          ? stringValue('readerRole', defaults.readerRole)
          : defaults.readerRole,
      readingComfort:
          const [
            'a_little',
            'moderate',
            'very',
            'depends',
            'unsure',
          ].contains(stringValue('readingComfort', defaults.readingComfort))
          ? stringValue('readingComfort', defaults.readingComfort)
          : defaults.readingComfort,
      readingChallenges: stringList(
        'readingChallenges',
        defaults.readingChallenges,
      ),
      supportStatus:
          const [
            'diagnosed',
            'seeking_support',
            'prefer_not_to_say',
          ].contains(stringValue('supportStatus', defaults.supportStatus))
          ? stringValue('supportStatus', defaults.supportStatus)
          : defaults.supportStatus,
      preferredLanguages: languages,
      defaultReadingLanguage: languages.contains(requestedDefault)
          ? requestedDefault
          : languages.first,
      fontFamily: AccessibilitySettings.fonts.contains(requestedFont)
          ? requestedFont
          : defaults.fontFamily,
      fontSize: numberValue(
        'fontSize',
        defaults.fontSize,
      ).clamp(16, 32).toDouble(),
      letterSpacing: numberValue(
        'letterSpacing',
        defaults.letterSpacing,
      ).clamp(0, 2).toDouble(),
      wordSpacing: numberValue(
        'wordSpacing',
        defaults.wordSpacing,
      ).clamp(0, 8).toDouble(),
      lineHeight: numberValue(
        'lineHeight',
        defaults.lineHeight,
      ).clamp(1.2, 2.5).toDouble(),
      colorTheme: supportedThemes.contains(requestedTheme)
          ? requestedTheme
          : defaults.colorTheme,
      wordHighlighting: boolValue(
        'wordHighlighting',
        defaults.wordHighlighting,
      ),
      focusLineMode: boolValue('focusLineMode', defaults.focusLineMode),
      readingRuler: boolValue('readingRuler', defaults.readingRuler),
      syllableBreakdown: boolValue(
        'syllableBreakdown',
        defaults.syllableBreakdown,
      ),
      breakLongSentences: boolValue(
        'breakLongSentences',
        defaults.breakLongSentences,
      ),
      simplifyText: boolValue('simplifyText', defaults.simplifyText),
      voiceAssistance: boolValue('voiceAssistance', defaults.voiceAssistance),
      voiceLanguage: stringValue('voiceLanguage', defaults.voiceLanguage),
      speechRate: numberValue(
        'speechRate',
        defaults.speechRate,
      ).clamp(0.1, 1.0).toDouble(),
      readingHighlight: boolValue(
        'readingHighlight',
        defaults.readingHighlight,
      ),
      largerControls: boolValue('largerControls', defaults.largerControls),
      highContrast: boolValue('highContrast', defaults.highContrast),
      reduceMotion: boolValue('reduceMotion', defaults.reduceMotion),
      readingGoals: stringList('readingGoals', defaults.readingGoals),
      materialTypes: stringList('materialTypes', defaults.materialTypes),
      explanationStyle: stringValue(
        'explanationStyle',
        defaults.explanationStyle,
      ),
      dailyTargetMinutes: json['dailyTargetMinutes'] is int
          ? (json['dailyTargetMinutes'] as int).clamp(0, 180).toInt()
          : defaults.dailyTargetMinutes,
      currentStep: savedStep is int ? savedStep.clamp(0, 4).toInt() : 0,
      completed: boolValue('completed', false),
    );
  }

  final String fullName;
  final String ageGroup;
  final String interfaceLanguage;
  final String readerRole;
  final String readingComfort;
  final List<String> readingChallenges;
  final String supportStatus;
  final List<String> preferredLanguages;
  final String defaultReadingLanguage;
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
  final bool breakLongSentences;
  final bool simplifyText;
  final bool voiceAssistance;
  final String voiceLanguage;
  final double speechRate;
  final bool readingHighlight;
  final bool largerControls;
  final bool highContrast;
  final bool reduceMotion;
  final List<String> readingGoals;
  final List<String> materialTypes;
  final String explanationStyle;
  final int dailyTargetMinutes;
  final int currentStep;
  final bool completed;

  OnboardingProfile copyWith({
    String? fullName,
    String? ageGroup,
    String? interfaceLanguage,
    String? readerRole,
    String? readingComfort,
    List<String>? readingChallenges,
    String? supportStatus,
    List<String>? preferredLanguages,
    String? defaultReadingLanguage,
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
    bool? breakLongSentences,
    bool? simplifyText,
    bool? voiceAssistance,
    String? voiceLanguage,
    double? speechRate,
    bool? readingHighlight,
    bool? largerControls,
    bool? highContrast,
    bool? reduceMotion,
    List<String>? readingGoals,
    List<String>? materialTypes,
    String? explanationStyle,
    int? dailyTargetMinutes,
    int? currentStep,
    bool? completed,
  }) => OnboardingProfile(
    fullName: fullName ?? this.fullName,
    ageGroup: ageGroup ?? this.ageGroup,
    interfaceLanguage: interfaceLanguage ?? this.interfaceLanguage,
    readerRole: readerRole ?? this.readerRole,
    readingComfort: readingComfort ?? this.readingComfort,
    readingChallenges: readingChallenges ?? this.readingChallenges,
    supportStatus: supportStatus ?? this.supportStatus,
    preferredLanguages: preferredLanguages ?? this.preferredLanguages,
    defaultReadingLanguage:
        defaultReadingLanguage ?? this.defaultReadingLanguage,
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
    breakLongSentences: breakLongSentences ?? this.breakLongSentences,
    simplifyText: simplifyText ?? this.simplifyText,
    voiceAssistance: voiceAssistance ?? this.voiceAssistance,
    voiceLanguage: voiceLanguage ?? this.voiceLanguage,
    speechRate: speechRate ?? this.speechRate,
    readingHighlight: readingHighlight ?? this.readingHighlight,
    largerControls: largerControls ?? this.largerControls,
    highContrast: highContrast ?? this.highContrast,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    readingGoals: readingGoals ?? this.readingGoals,
    materialTypes: materialTypes ?? this.materialTypes,
    explanationStyle: explanationStyle ?? this.explanationStyle,
    dailyTargetMinutes: dailyTargetMinutes ?? this.dailyTargetMinutes,
    currentStep: currentStep ?? this.currentStep,
    completed: completed ?? this.completed,
  );

  Map<String, Object?> toJson() => {
    'fullName': fullName,
    'ageGroup': ageGroup,
    'interfaceLanguage': interfaceLanguage,
    'readerRole': readerRole,
    'readingComfort': readingComfort,
    'readingChallenges': readingChallenges,
    'supportStatus': supportStatus,
    'preferredLanguages': preferredLanguages,
    'defaultReadingLanguage': defaultReadingLanguage,
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
    'breakLongSentences': breakLongSentences,
    'simplifyText': simplifyText,
    'voiceAssistance': voiceAssistance,
    'voiceLanguage': voiceLanguage,
    'speechRate': speechRate,
    'readingHighlight': readingHighlight,
    'largerControls': largerControls,
    'highContrast': highContrast,
    'reduceMotion': reduceMotion,
    'readingGoals': readingGoals,
    'materialTypes': materialTypes,
    'explanationStyle': explanationStyle,
    'dailyTargetMinutes': dailyTargetMinutes,
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
    if (profile.currentStep < 0 || profile.currentStep > 4) {
      throw ArgumentError.value(profile.currentStep, 'currentStep');
    }
    if (profile.completed &&
        (profile.fullName.trim().isEmpty ||
            profile.preferredLanguages.isEmpty ||
            !profile.preferredLanguages.contains(
              profile.defaultReadingLanguage,
            ))) {
      throw ArgumentError(
        'Completed onboarding requires a name and a default reading language.',
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(uid), jsonEncode(profile.toJson()));
  }

  Future<void> clear(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(uid));
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
    AccessibilitySettings.wordHighlighting =
        profile.wordHighlighting && profile.readingHighlight;
    AccessibilitySettings.focusLineMode = profile.focusLineMode;
    AccessibilitySettings.readingRuler = profile.readingRuler;
    AccessibilitySettings.syllableBreakdown = profile.syllableBreakdown;
    await AccessibilitySettings.save();

    UIAccessibility.fontFamily = profile.fontFamily;
    UIAccessibility.fontSize = profile.fontSize;
    UIAccessibility.letterSpacing = profile.letterSpacing;
    UIAccessibility.wordSpacing = profile.wordSpacing;
    UIAccessibility.lineHeight = profile.lineHeight;
    UIAccessibility.activeColorTheme = profile.colorTheme;
    UIAccessibility.backgroundColor = UIAccessibility.themeBg(
      profile.colorTheme,
    );
    UIAccessibility.textColor = UIAccessibility.themeText(profile.colorTheme);
    UIAccessibility.highContrastEnabled = profile.highContrast;
    UIAccessibility.reducedAnimationsEnabled = profile.reduceMotion;
    UIAccessibility.largeTouchTargetsEnabled = profile.largerControls;
    UIAccessibility.notifier.value++;
    await UIAccessibility.save();
    AppSettings.language = profile.defaultReadingLanguage;
    AppSettings.interfaceLanguage = profile.interfaceLanguage;
    AppSettings.voiceAssistanceEnabled = profile.voiceAssistance;
    await AppSettings.saveVoiceAssistancePreference(profile.voiceAssistance);
    await AppSettings.saveVoiceLanguagePreference(
      profile.voiceLanguage,
      localeId: null,
    );
    AppSettings.speechRate = profile.speechRate;
    AppSettings.readingHighlight = profile.readingHighlight;
    AppSettings.autoSimplifyText = profile.simplifyText;
  }
}
