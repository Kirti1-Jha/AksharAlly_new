import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:firebase_core/firebase_core.dart' show FirebaseException;

import '../services/onboarding_storage.dart';
import '../services/user_profile_service.dart';
import '../theme/accessibility_settings.dart';
import '../theme/app_settings.dart';
import '../theme/app_theme.dart';
import '../theme/ui_accessibility.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.uid,
    required this.initialProfile,
    required this.storage,
    this.accountStore,
  });

  final String uid;
  final OnboardingProfile initialProfile;
  final OnboardingStorage storage;
  final OnboardingAccountStore? accountStore;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _themeChoices = [
    'cream_black',
    'soft_yellow_black',
    'pale_blue_navy',
    'pale_green_gray',
    'white_black',
  ];

  late OnboardingProfile _profile;
  late final TextEditingController _nameController;
  late final ThemeData _accessibilityTheme = UIAccessibility.buildTheme();
  Future<void> _saveQueue = Future<void>.value();
  late final OnboardingAccountStore _accountStore =
      widget.accountStore ?? const FirestoreOnboardingAccountStore();
  String? _saveError;
  String? _saveDiagnostics;
  bool _finishing = false;
  bool _customizeReading = false;

  bool get _hindi => AppSettings.interfaceLanguage == 'hi';
  String _tr(String english, String hindi) => _hindi ? hindi : english;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    if (!_profile.completed && _profile.questionnaireVersion < 2) {
      final oldStep = _profile.questionnaireVersion == 0
          ? switch (_profile.currentStep.clamp(0, 4).toInt()) {
              0 => 0,
              1 => 1,
              2 => 4,
              3 => 7,
              _ => 9,
            }
          : _profile.currentStep.clamp(0, 11).toInt();
      final migratedPage = switch (oldStep) {
        0 => 0,
        1 => 1,
        2 || 3 => 2,
        >= 4 && <= 8 => 3,
        9 || 10 => 6,
        _ => 7,
      };
      final now = DateTime.now().toUtc().microsecondsSinceEpoch;
      _profile = _profile.copyWith(
        currentStep: migratedPage,
        questionnaireVersion: 2,
        updatedAt: now > _profile.updatedAt ? now : _profile.updatedAt + 1,
      );
      _persist(_profile);
    }
    _customizeReading = const [4, 5, 8, 9].contains(_profile.currentStep);
    _nameController = TextEditingController(text: _profile.fullName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _update(OnboardingProfile next) {
    final updated = next.copyWith(updatedAt: _nextUpdatedAt());
    setState(() {
      _profile = updated;
      _saveError = null;
      _saveDiagnostics = null;
    });
    _persist(updated);
  }

  int _nextUpdatedAt() {
    final now = DateTime.now().toUtc().microsecondsSinceEpoch;
    return now > _profile.updatedAt ? now : _profile.updatedAt + 1;
  }

  void _persist(OnboardingProfile snapshot) {
    _saveQueue = _saveQueue
        .then((_) async {
          await widget.storage.save(widget.uid, snapshot);
        })
        .catchError((Object error, StackTrace stackTrace) {
          _logSaveFailure('draft save', error, stackTrace);
          if (mounted) {
            setState(() {
              _saveError = _tr(
                'Your progress could not be saved. Check your device storage and try again.',
                'आपकी प्रगति सहेजी नहीं जा सकी। डिवाइस स्टोरेज जाँचें और फिर कोशिश करें।',
              );
              _saveDiagnostics = kDebugMode ? _saveFailureDetails(error) : null;
            });
          }
        });
  }

  Future<void> _goToPage(int step, List<_QuestionnairePage> pages) async {
    if (_saveError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_saveError!)));
      return;
    }
    if (_profile.currentStep == 0 && _profile.fullName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'Add a preferred name to continue.',
              'आगे बढ़ने के लिए अपना पसंदीदा नाम लिखें।',
            ),
          ),
        ),
      );
      return;
    }
    if (step < 0 || step >= pages.length) return;
    final next = _profile.copyWith(currentStep: pages[step].id);
    _update(next);
    await _saveQueue;
  }

  Future<void> _finish(int finalPageId) async {
    if (_finishing) return;
    if (_profile.fullName.trim().isEmpty ||
        _profile.preferredLanguages.isEmpty ||
        !_profile.preferredLanguages.contains(
          _profile.defaultReadingLanguage,
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'Add your preferred name and choose at least one reading language.',
              'अपना पसंदीदा नाम और पढ़ने की कम-से-कम एक भाषा चुनें।',
            ),
          ),
        ),
      );
      return;
    }
    setState(() {
      _finishing = true;
      _saveError = null;
      _saveDiagnostics = null;
    });
    try {
      await _saveQueue;
      if (_saveError != null) {
        throw StateError('The local onboarding draft could not be saved.');
      }
      final complete = _profile.copyWith(
        completed: true,
        currentStep: finalPageId,
        questionnaireVersion: 2,
        updatedAt: _nextUpdatedAt(),
      );
      await _accountStore.saveOnboarding(widget.uid, complete);
      await widget.storage.save(widget.uid, complete);
      await widget.storage.applyReadingPreferences(
        complete,
        applyGlobalSettings: false,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } catch (error, stackTrace) {
      _logSaveFailure('finish', error, stackTrace);
      if (mounted) {
        setState(() {
          _finishing = false;
          _saveDiagnostics = kDebugMode ? _saveFailureDetails(error) : null;
          _saveError = _tr(
            'Your profile could not be saved. Please try again.',
            'आपकी प्रोफ़ाइल सहेजी नहीं जा सकी। फिर से कोशिश करें।',
          );
        });
      }
    }
  }

  String _saveFailureDetails(Object error) {
    if (error is FirebaseException) {
      final message = error.message;
      return '${error.plugin}/${error.code}'
          '${message == null || message.isEmpty ? '' : ': $message'}';
    }
    return '${error.runtimeType}: $error';
  }

  void _logSaveFailure(String operation, Object error, StackTrace stackTrace) {
    if (!kDebugMode) return;
    debugPrint(
      'Onboarding profile $operation failed: '
      '${_saveFailureDetails(error)}',
    );
    if (error is! FirebaseException) debugPrintStack(stackTrace: stackTrace);
  }

  String _label(String value) {
    if (!_hindi) {
      return switch (value) {
        'en' => 'English',
        'hi' => 'Hindi',
        'mr' => 'Marathi',
        'under_13' => 'Under 13',
        '13_17' => '13–17',
        '18_24' => '18–24',
        '25_44' => '25–44',
        '45_plus' => '45+',
        'child' => 'Helping a child',
        'teacher' => 'Teaching',
        'supporting' => 'Supporting another reader',
        'self' => 'Reading for myself',
        'a_little' => 'A little challenging',
        'moderate' => 'Moderately challenging',
        'very' => 'Very challenging',
        'depends' => 'Depends on the material',
        'unsure' => 'Not sure',
        'long_sentences' => 'Long sentences',
        'crowded_text' => 'Crowded text',
        'similar_letters' => 'Similar-looking letters',
        'losing_place' => 'Losing my place',
        'unfamiliar_words' => 'Unfamiliar words',
        'long_sessions' => 'Reading for a long time',
        'prefer_not_to_say' => 'Prefer not to say',
        'diagnosed' => 'I have a dyslexia diagnosis',
        'seeking_support' => 'I am exploring reading support',
        'independent' => 'Independent reading',
        'understanding' => 'Understanding text',
        'study' => 'Study support',
        'confidence' => 'Reading confidence',
        'multilingual' => 'Multilingual reading',
        'textbooks' => 'Textbooks',
        'stories' => 'Stories',
        'articles' => 'Articles',
        'notes' => 'Notes',
        'scanned_pages' => 'Scanned pages',
        'documents' => 'Other documents',
        'shorter_sentences' => 'Shorter sentences',
        'simpler_text' => 'Simpler text',
        'word_explanations' => 'Extra word explanations',
        _ => value,
      };
    }
    return switch (value) {
      'en' => 'अंग्रेज़ी',
      'hi' => 'हिंदी',
      'mr' => 'मराठी',
      'under_13' => '13 वर्ष से कम',
      '13_17' => '13–17',
      '18_24' => '18–24',
      '25_44' => '25–44',
      '45_plus' => '45+',
      'child' => 'बच्चे की मदद करना',
      'teacher' => 'पढ़ाना',
      'supporting' => 'किसी पाठक की सहायता करना',
      'self' => 'अपने लिए पढ़ना',
      'a_little' => 'थोड़ी कठिनाई',
      'moderate' => 'मध्यम कठिनाई',
      'very' => 'बहुत कठिनाई',
      'depends' => 'पाठ्य सामग्री पर निर्भर',
      'unsure' => 'पता नहीं',
      'long_sentences' => 'लंबे वाक्य',
      'crowded_text' => 'घना पाठ',
      'similar_letters' => 'मिलते-जुलते अक्षर',
      'losing_place' => 'पढ़ते समय जगह भूलना',
      'unfamiliar_words' => 'अपरिचित शब्द',
      'long_sessions' => 'लंबे समय तक पढ़ना',
      'prefer_not_to_say' => 'बताना नहीं चाहते',
      'diagnosed' => 'मुझे डिस्लेक्सिया का निदान मिला है',
      'seeking_support' => 'मैं पढ़ने में सहायता देख रहा/रही हूँ',
      'independent' => 'स्वतंत्र रूप से पढ़ना',
      'understanding' => 'पाठ समझना',
      'study' => 'पढ़ाई में सहायता',
      'confidence' => 'पढ़ने का आत्मविश्वास',
      'multilingual' => 'कई भाषाओं में पढ़ना',
      'textbooks' => 'पाठ्यपुस्तकें',
      'stories' => 'कहानियाँ',
      'articles' => 'लेख',
      'notes' => 'नोट्स',
      'scanned_pages' => 'स्कैन किए पन्ने',
      'documents' => 'अन्य दस्तावेज़',
      'shorter_sentences' => 'छोटे वाक्य',
      'simpler_text' => 'सरल पाठ',
      'word_explanations' => 'शब्दों के अतिरिक्त अर्थ',
      _ => value,
    };
  }

  Widget _section(String title, Widget child, {String? helper}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: UIAccessibility.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: BorderSide(color: UIAccessibility.textColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: _accessibilityTheme.textTheme.titleMedium
                  ?.copyWith(color: UIAccessibility.textColor),
            ),
            if (helper != null) ...[
              const SizedBox(height: 5),
              Text(
                helper,
                style: _accessibilityTheme.textTheme.bodySmall
                    ?.copyWith(
                      color: UIAccessibility.textColor.withOpacity(0.75),
                    ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _chips(
    String title,
    List<String> values,
    List<String> selected,
    void Function(List<String>) onChanged, {
    bool single = false,
    String? helper,
  }) {
    return _section(
      title,
      Wrap(
        spacing: 8,
        runSpacing: 2,
        children: values.map((value) {
          final isSelected = selected.contains(value);
          return FilterChip(
            label: Text(_label(value)),
            selected: isSelected,
            onSelected: (_) {
              if (single) {
                onChanged([value]);
              } else {
                final next = List<String>.from(selected);
                isSelected ? next.remove(value) : next.add(value);
                onChanged(next);
              }
            },
            selectedColor: AppTheme.primaryBlue.withOpacity(0.14),
            checkmarkColor: AppTheme.primaryBlue,
          );
        }).toList(),
      ),
      helper: helper,
    );
  }

  Widget _slider({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String valueText,
    required ValueChanged<double> onChanged,
  }) {
    return _section(
      '$title · $valueText',
      Slider(
        value: value.clamp(min, max).toDouble(),
        min: min,
        max: max,
        divisions: divisions,
        activeColor: AppTheme.primaryBlue,
        onChanged: onChanged,
      ),
    );
  }

  List<Widget> _aboutYouQuestions() => [
        _section(
          _tr('What should we call you?', 'हम आपको किस नाम से बुलाएँ?'),
          TextField(
            key: const ValueKey('onboarding-name'),
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            maxLength: 60,
            decoration: InputDecoration(
              hintText: _tr('Preferred name', 'पसंदीदा नाम'),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) =>
                _update(_profile.copyWith(fullName: value.trimLeft())),
          ),
        ),
        _chips(
          _tr('Age group (optional)', 'आयु वर्ग (वैकल्पिक)'),
          const ['under_13', '13_17', '18_24', '25_44', '45_plus'],
          [_profile.ageGroup],
          (selected) => _update(_profile.copyWith(ageGroup: selected.first)),
          single: true,
        ),
        _chips(
          _tr('Who are you reading for?', 'आप किसके लिए पढ़ रहे हैं?'),
          const ['self', 'child', 'teacher', 'supporting'],
          [_profile.readerRole],
          (selected) => _update(_profile.copyWith(readerRole: selected.first)),
          single: true,
        ),
      ];

  List<Widget> _readingNeedsQuestions() => [
    _chips(
      _tr('How comfortable does reading feel?', 'पढ़ना आपको कैसा लगता है?'),
      const ['a_little', 'moderate', 'very', 'depends', 'unsure'],
      [_profile.readingComfort],
      (selected) => _update(_profile.copyWith(readingComfort: selected.first)),
      single: true,
    ),
    _chips(
      _tr('What can make reading harder?', 'पढ़ने में क्या कठिन हो सकता है?'),
      const [
        'long_sentences',
        'crowded_text',
        'similar_letters',
        'losing_place',
        'unfamiliar_words',
        'long_sessions',
      ],
      _profile.readingChallenges,
      (selected) => _update(_profile.copyWith(readingChallenges: selected)),
    ),
    _chips(
      _tr('Which languages do you read?', 'आप किन भाषाओं में पढ़ते हैं?'),
      const ['en', 'hi', 'mr'],
      _profile.preferredLanguages,
      (selected) {
        final safe = selected.isEmpty ? const ['en'] : selected;
        final defaultLanguage = safe.contains(_profile.defaultReadingLanguage)
            ? _profile.defaultReadingLanguage
            : safe.first;
        _update(
          _profile.copyWith(
            preferredLanguages: safe,
            defaultReadingLanguage: defaultLanguage,
          ),
        );
      },
    ),
  ];

  List<Widget> _readingGoalsQuestions() => [
    _chips(
      _tr('What would you like help with?', 'आप किसमें सहायता चाहते हैं?'),
      const ['independent', 'understanding', 'study', 'confidence', 'multilingual'],
      _profile.readingGoals,
      (selected) => _update(_profile.copyWith(readingGoals: selected)),
    ),
    _chips(
      _tr('What do you usually read?', 'आप आमतौर पर क्या पढ़ते हैं?'),
      const ['textbooks', 'stories', 'articles', 'notes', 'scanned_pages', 'documents'],
      _profile.materialTypes,
      (selected) => _update(_profile.copyWith(materialTypes: selected)),
    ),
    _slider(
      title: _tr(
        'Daily reading target (optional)',
        'रोज़ पढ़ने का लक्ष्य (वैकल्पिक)',
      ),
      value: _profile.dailyTargetMinutes.toDouble(),
      min: 0,
      max: 60,
      divisions: 12,
      valueText: _profile.dailyTargetMinutes == 0
          ? _tr('No target', 'कोई लक्ष्य नहीं')
          : '${_profile.dailyTargetMinutes} ${_tr('min', 'मिनट')}',
      onChanged: (value) => _update(
        _profile.copyWith(dailyTargetMinutes: (value / 5).round() * 5),
      ),
    ),
  ];

  OnboardingProfile _profileForSuggestion(String key) {
    return switch (key) {
      'dyslexia' => _profile.copyWith(
        fontFamily: 'OpenDyslexic',
        fontSize: 16,
        letterSpacing: 0.3,
        wordSpacing: 2,
        lineHeight: 1.6,
        colorTheme: 'cream_black',
      ),
      'eye_strain' => _profile.copyWith(
        fontFamily: 'Inter',
        fontSize: 16,
        letterSpacing: 0.2,
        wordSpacing: 1.5,
        lineHeight: 1.5,
        colorTheme: 'soft_yellow_black',
      ),
      'clarity' => _profile.copyWith(
        fontFamily: 'Roboto',
        fontSize: 20,
        letterSpacing: 0.5,
        wordSpacing: 3,
        lineHeight: 1.8,
        colorTheme: 'white_black',
      ),
      _ => _profile.copyWith(
        fontFamily: 'OpenDyslexic',
        fontSize: 24,
        letterSpacing: 0.5,
        wordSpacing: 4,
        lineHeight: 2,
        colorTheme: 'pale_blue_navy',
      ),
    };
  }

  Future<void> _selectSuggestedProfile(String key) async {
    _update(_profileForSuggestion(key));
    await _saveQueue;
    if (!mounted || _saveError != null) return;
    setState(() => _customizeReading = false);
    final pages = _questionPages();
    final profilePage = pages.indexWhere((page) => page.id == 3);
    if (profilePage >= 0) await _goToPage(profilePage + 1, pages);
  }

  Future<void> _openManualPreferences() async {
    setState(() => _customizeReading = true);
    _update(_profile.copyWith(currentStep: 4));
    await _saveQueue;
  }

  String _suggestedProfileTitle(String key) => switch (key) {
    'dyslexia' => _tr('Dyslexia Recommended', 'डिस्लेक्सिया के लिए सुझाया गया'),
    'eye_strain' => _tr('Low Eye Strain', 'आँखों पर कम दबाव'),
    'clarity' => _tr('Maximum Clarity', 'अधिकतम स्पष्टता'),
    _ => _tr('Beginner Reader', 'नए पाठक'),
  };

  String _suggestedProfileDescription(String key) => switch (key) {
    'dyslexia' => _tr(
      'OpenDyslexic · Cream · Generous spacing',
      'OpenDyslexic · क्रीम · अधिक अक्षर दूरी',
    ),
    'eye_strain' => _tr(
      'Inter · Soft Yellow · Reduced glare',
      'Inter · हल्का पीला · कम चमक',
    ),
    'clarity' => _tr(
      'Roboto · White · Large, spaced text',
      'Roboto · सफ़ेद · बड़ा और खुला पाठ',
    ),
    _ => _tr(
      'OpenDyslexic · Light Blue · Very large text',
      'OpenDyslexic · हल्का नीला · बहुत बड़ा पाठ',
    ),
  };

  Widget _suggestedProfileCard(String key) {
    final suggestion = _profileForSuggestion(key);
    final background = AccessibilitySettings.previewBg(suggestion.colorTheme);
    final foreground = AccessibilitySettings.previewText(suggestion.colorTheme);
    final label = _suggestedProfileTitle(key);
    return Semantics(
      button: true,
      label: '$label. ${_suggestedProfileDescription(key)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        onTap: () => _selectSuggestedProfile(key),
        child: Container(
          width: 164,
          margin: const EdgeInsets.only(right: AppTheme.spaceSM),
          padding: const EdgeInsets.all(AppTheme.spaceSM),
          decoration: BoxDecoration(
            color: UIAccessibility.backgroundColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(
              color: UIAccessibility.textColor.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 42,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Aa',
                  style: UIAccessibility.previewStyleFor(
                    suggestion.fontFamily,
                  ).copyWith(
                    color: foreground,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _accessibilityTheme.textTheme.titleSmall?.copyWith(
                  color: UIAccessibility.textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  _suggestedProfileDescription(key),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: _accessibilityTheme.textTheme.bodySmall?.copyWith(
                    color: UIAccessibility.textColor.withOpacity(0.75),
                  ),
                ),
              ),
              Text(
                _tr('Select', 'चुनें'),
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _readingPreviewCard() {
    final background = AccessibilitySettings.previewBg(_profile.colorTheme);
    final foreground = AccessibilitySettings.previewText(_profile.colorTheme);
    final textStyle = UIAccessibility.previewStyleFor(_profile.fontFamily)
        .copyWith(
          color: foreground,
          fontSize: _profile.fontSize,
          height: _profile.lineHeight,
          letterSpacing: _profile.letterSpacing,
          wordSpacing: _profile.wordSpacing,
        );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: foreground.withOpacity(0.25)),
      ),
      child: Text(
        _tr(
          'A calm space to read, one clear line at a time.',
          'पढ़ने के लिए एक शांत जगह, हर बार एक स्पष्ट पंक्ति।',
        ),
        style: textStyle,
      ),
    );
  }

  Widget _suggestedProfilesPage() => Column(
    children: [
      _section(
        _tr('Choose a reading profile', 'पढ़ने की शैली चुनें'),
        SizedBox(
          height: 194,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: UIAccessibility.profileLabels.keys
                .map(_suggestedProfileCard)
                .toList(),
          ),
        ),
      ),
      _section(
        _tr('Live preview', 'लाइव झलक'),
        _readingPreviewCard(),
      ),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _openManualPreferences,
          icon: const Icon(Icons.tune_rounded),
          label: Text(_tr('Customize', 'अपने अनुसार बदलें')),
        ),
      ),
    ],
  );

  Widget _previewButton() => Align(
    alignment: Alignment.centerRight,
    child: TextButton.icon(
      onPressed: _showSelectedReadingPreview,
      icon: const Icon(Icons.visibility_outlined),
      label: Text(_tr('Preview', 'झलक')),
    ),
  );

  Future<void> _showSelectedReadingPreview() => showDialog<void>(
    context: context,
    builder: (context) {
      final background = AccessibilitySettings.previewBg(_profile.colorTheme);
      final foreground = AccessibilitySettings.previewText(_profile.colorTheme);
      return AlertDialog(
        title: Text(_tr('Reading preview', 'पढ़ने की झलक')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _readingPreviewCard(),
              const SizedBox(height: 12),
              Text(_tr('Selected settings', 'चुनी गई सेटिंग')),
              Text('${_tr('Font', 'फ़ॉन्ट')}: ${_profile.fontFamily}'),
              Text(
                '${_tr('Text size', 'पाठ का आकार')}: '
                '${_profile.fontSize.round()} px',
              ),
              Text(
                '${_tr('Letter spacing', 'अक्षरों के बीच दूरी')}: '
                '${_profile.letterSpacing.toStringAsFixed(1)}',
              ),
              Text(
                '${_tr('Word spacing', 'शब्दों के बीच दूरी')}: '
                '${_profile.wordSpacing.toStringAsFixed(1)}',
              ),
              Text(
                '${_tr('Line spacing', 'पंक्तियों के बीच दूरी')}: '
                '${_profile.lineHeight.toStringAsFixed(1)}',
              ),
              Text(
                '${_tr('Colors', 'रंग')}: '
                '${AccessibilitySettings.themeLabels[_profile.colorTheme]}',
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: foreground.withOpacity(0.4)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_tr('Close', 'बंद करें')),
          ),
        ],
      );
    },
  );

  List<Widget> _manualReadingPageOne() => [
    _section(
      _tr('Font style', 'फ़ॉन्ट शैली'),
      DropdownButtonFormField<String>(
        value: AccessibilitySettings.fonts.contains(_profile.fontFamily)
            ? _profile.fontFamily
            : 'Lexend',
        isExpanded: true,
        items: AccessibilitySettings.fonts
            .map((name) => DropdownMenuItem(value: name, child: Text(name)))
            .toList(),
        onChanged: (value) {
          if (value != null) _update(_profile.copyWith(fontFamily: value));
        },
      ),
    ),
    _slider(
      title: _tr('Font size', 'फ़ॉन्ट का आकार'),
      value: _profile.fontSize,
      min: 16,
      max: 32,
      divisions: 16,
      valueText: '${_profile.fontSize.round()} px',
      onChanged: (value) => _update(_profile.copyWith(fontSize: value)),
    ),
    _slider(
      title: _tr('Letter spacing', 'अक्षरों के बीच दूरी'),
      value: _profile.letterSpacing,
      min: 0,
      max: 2,
      divisions: 8,
      valueText: _profile.letterSpacing.toStringAsFixed(1),
      onChanged: (value) => _update(_profile.copyWith(letterSpacing: value)),
    ),
    _previewButton(),
  ];

  List<Widget> _manualReadingPageTwo() => [
    _slider(
      title: _tr('Word spacing', 'शब्दों के बीच दूरी'),
      value: _profile.wordSpacing,
      min: 0,
      max: 8,
      divisions: 8,
      valueText: _profile.wordSpacing.toStringAsFixed(1),
      onChanged: (value) => _update(_profile.copyWith(wordSpacing: value)),
    ),
    _slider(
      title: _tr('Line spacing', 'पंक्तियों के बीच दूरी'),
      value: _profile.lineHeight,
      min: 1.2,
      max: 2.5,
      divisions: 13,
      valueText: _profile.lineHeight.toStringAsFixed(1),
      onChanged: (value) => _update(_profile.copyWith(lineHeight: value)),
    ),
    _section(
      _tr('Background and text colors', 'पृष्ठभूमि और पाठ के रंग'),
      DropdownButtonFormField<String>(
        value: _themeChoices.contains(_profile.colorTheme)
            ? _profile.colorTheme
            : 'soft_yellow_black',
        isExpanded: true,
        items: _themeChoices.map((key) {
          return DropdownMenuItem(
            value: key,
            child: Text(AccessibilitySettings.themeLabels[key]!),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) _update(_profile.copyWith(colorTheme: value));
        },
      ),
    ),
    _previewButton(),
  ];

  List<_QuestionnairePage> _questionPages() {
    final about = _aboutYouQuestions();
    final reading = _readingNeedsQuestions();
    final goals = _readingGoalsQuestions();
    return [
      _QuestionnairePage(
        id: 0,
        content: Column(children: [about[0], about[1]]),
      ),
      _QuestionnairePage(
        id: 1,
        content: Column(children: [about[2], reading[0]]),
      ),
      _QuestionnairePage(
        id: 2,
        content: Column(children: [reading[1], reading[2]]),
      ),
      _QuestionnairePage(id: 3, content: _suggestedProfilesPage()),
      if (_customizeReading) ...[
        _QuestionnairePage(
          id: 4,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _tr('Customize reading · 1 of 2', 'रीडिंग बदलें · 1 / 2'),
                style: _accessibilityTheme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ..._manualReadingPageOne(),
            ],
          ),
        ),
        _QuestionnairePage(
          id: 5,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _tr('Customize reading · 2 of 2', 'रीडिंग बदलें · 2 / 2'),
                style: _accessibilityTheme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ..._manualReadingPageTwo(),
            ],
          ),
        ),
      ],
      _QuestionnairePage(
        id: _customizeReading ? 8 : 6,
        content: Column(children: [goals[0], goals[1]]),
      ),
      _QuestionnairePage(
        id: _customizeReading ? 9 : 7,
        content: goals[2],
      ),
    ];
  }

  Widget _backButton(int step, List<_QuestionnairePage> pages) => OutlinedButton(
    onPressed: _finishing ? null : () => _goToPage(step - 1, pages),
    child: Text(_tr('Back', 'पीछे')),
  );

  Widget _continueButton(
    int step,
    List<_QuestionnairePage> pages, {
    bool expand = false,
  }) => FilledButton.icon(
    key: ValueKey(
      step == pages.length - 1 ? 'onboarding-finish' : 'onboarding-next',
    ),
    style: FilledButton.styleFrom(
      minimumSize: Size(expand ? double.infinity : 136, 52),
    ),
    onPressed: _finishing
        ? null
        : step == pages.length - 1
        ? () => _finish(pages[step].id)
        : () => _goToPage(step + 1, pages),
    icon: _finishing
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(
            step == pages.length - 1
                ? Icons.check_rounded
                : Icons.arrow_forward_rounded,
          ),
    label: Text(
      _finishing
          ? _tr('Saving…', 'सहेज रहे हैं…')
          : step == pages.length - 1
          ? _tr('Finish', 'पूरा करें')
          : _tr('Continue', 'आगे बढ़ें'),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final pages = _questionPages();
    final pageCount = pages.length;
    final savedPage = pages.indexWhere(
      (page) => page.id == _profile.currentStep,
    );
    final step = savedPage < 0 ? 0 : savedPage;
    final currentPage = pages[step];
    final screenTheme = _accessibilityTheme.copyWith(
      appBarTheme: _accessibilityTheme.appBarTheme.copyWith(
        titleTextStyle: _accessibilityTheme.appBarTheme.titleTextStyle
            ?.copyWith(color: UIAccessibility.textColor),
      ),
      inputDecorationTheme: _accessibilityTheme.inputDecorationTheme.copyWith(
        fillColor: UIAccessibility.backgroundColor,
      ),
    );
    return Theme(
      data: screenTheme,
      child: Scaffold(
      backgroundColor: UIAccessibility.backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          _tr('Personalise your reading', 'अपना पढ़ने का अनुभव बनाएँ'),
        ),
        backgroundColor: UIAccessibility.backgroundColor,
        foregroundColor: UIAccessibility.textColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr(
                          'Step ${step + 1} of $pageCount',
                          'चरण ${step + 1} / $pageCount',
                        ),
                        style: _accessibilityTheme.textTheme.bodyMedium
                            ?.copyWith(
                              color: UIAccessibility.textColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (step + 1) / pageCount,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(10),
                        backgroundColor: UIAccessibility.textColor.withOpacity(
                          0.12,
                        ),
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _tr('Your preferences', 'आपकी प्राथमिकताएँ'),
                        style: _accessibilityTheme
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: UIAccessibility.textColor,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    key: ValueKey('onboarding-step-${currentPage.id}'),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Column(
                      children: [
                        currentPage.content,
                        if (_saveError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              children: [
                                Text(
                                  _saveError!,
                                  style: _accessibilityTheme
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppTheme.error),
                                  textAlign: TextAlign.center,
                                ),
                                if (kDebugMode && _saveDiagnostics != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: SelectableText(
                                      _saveDiagnostics!,
                                      textAlign: TextAlign.center,
                                      style: _accessibilityTheme
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Container(
                  color: UIAccessibility.backgroundColor,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact =
                          constraints.maxWidth < 400 || step == pageCount - 1;
                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (step > 0) ...[
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _backButton(step, pages),
                              ),
                              const SizedBox(height: 8),
                            ],
                            _continueButton(step, pages, expand: true),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          if (step > 0) _backButton(step, pages),
                          if (step > 0) const SizedBox(width: 10),
                          const Spacer(),
                          _continueButton(step, pages),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _QuestionnairePage {
  const _QuestionnairePage({required this.id, required this.content});

  final int id;
  final Widget content;
}
