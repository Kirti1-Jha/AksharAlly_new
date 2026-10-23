import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:firebase_core/firebase_core.dart' show FirebaseException;

import '../services/onboarding_storage.dart';
import '../services/user_profile_service.dart';
import '../theme/accessibility_settings.dart';
import '../theme/app_settings.dart';
import '../theme/app_theme.dart';

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
  static const _stepTitles = [
    'About you',
    'Reading needs',
    'Reading appearance',
    'Voice and access',
    'Reading goals',
  ];

  static const _themeChoices = [
    'cream_black',
    'soft_yellow_black',
    'pale_blue_navy',
    'pale_green_gray',
    'white_black',
  ];

  late OnboardingProfile _profile;
  late final TextEditingController _nameController;
  Future<void> _saveQueue = Future<void>.value();
  late final OnboardingAccountStore _accountStore =
      widget.accountStore ?? const FirestoreOnboardingAccountStore();
  String? _saveError;
  String? _saveDiagnostics;
  bool _finishing = false;

  bool get _hindi => AppSettings.interfaceLanguage == 'hi';
  String _tr(String english, String hindi) => _hindi ? hindi : english;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _nameController = TextEditingController(text: _profile.fullName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _update(OnboardingProfile next) {
    setState(() {
      _profile = next;
      _saveError = null;
      _saveDiagnostics = null;
    });
    _persist(next);
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

  Future<void> _selectInterfaceLanguage(String language) async {
    try {
      await AppSettings.saveInterfaceLanguagePreference(language);
    } catch (error, stackTrace) {
      _logSaveFailure('interface language save', error, stackTrace);
      if (mounted) {
        setState(() {
          _saveError = _tr(
            'The interface language could not be saved. Please try again.',
            'ऐप की भाषा सहेजी नहीं जा सकी। कृपया फिर कोशिश करें।',
          );
        });
      }
      return;
    }
    if (!mounted) return;
    final updated = _profile.copyWith(interfaceLanguage: language);
    setState(() {
      _profile = updated;
      _saveError = null;
      _saveDiagnostics = null;
    });
    _persist(updated);
  }

  Future<void> _goTo(int step) async {
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
    final next = _profile.copyWith(currentStep: step);
    _update(next);
    await _saveQueue;
  }

  Future<void> _finish() async {
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
              'Add your preferred name and choose a default reading language.',
              'अपना पसंदीदा नाम और पढ़ने की डिफ़ॉल्ट भाषा चुनें।',
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
      final complete = _profile.copyWith(completed: true, currentStep: 4);
      await _accountStore.saveOnboarding(widget.uid, complete);
      await widget.storage.save(widget.uid, complete);
      await widget.storage.applyReadingPreferences(complete);
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
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.09)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (helper != null) ...[
              const SizedBox(height: 5),
              Text(
                helper,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
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

  Widget _toggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryBlue,
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

  Widget _aboutYou() {
    return Column(
      children: [
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
        _section(
          _tr('Interface language', 'ऐप की भाषा'),
          Wrap(
            spacing: 8,
            children: [
              for (final item in const [('en', 'English'), ('hi', 'हिंदी')])
                ChoiceChip(
                  label: Text(item.$2),
                  selected: AppSettings.interfaceLanguage == item.$1,
                  onSelected: (_) =>
                      _selectInterfaceLanguage(item.$1),
                ),
            ],
          ),
        ),
        _chips(
          _tr('Who are you reading for?', 'आप किसके लिए पढ़ रहे हैं?'),
          const ['self', 'child', 'teacher', 'supporting'],
          [_profile.readerRole],
          (selected) => _update(_profile.copyWith(readerRole: selected.first)),
          single: true,
        ),
      ],
    );
  }

  Widget _readingNeeds() {
    return Column(
      children: [
        _chips(
          _tr('How comfortable does reading feel?', 'पढ़ना आपको कैसा लगता है?'),
          const ['a_little', 'moderate', 'very', 'depends', 'unsure'],
          [_profile.readingComfort],
          (selected) =>
              _update(_profile.copyWith(readingComfort: selected.first)),
          single: true,
        ),
        _chips(
          _tr(
            'What can make reading harder?',
            'पढ़ने में क्या कठिन हो सकता है?',
          ),
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
          _tr('Reading support (optional)', 'पढ़ने में सहायता (वैकल्पिक)'),
          const ['diagnosed', 'seeking_support', 'prefer_not_to_say'],
          [_profile.supportStatus],
          (selected) =>
              _update(_profile.copyWith(supportStatus: selected.first)),
          single: true,
          helper: _tr(
            'This is optional and does not diagnose you.',
            'यह वैकल्पिक है और इससे कोई निदान नहीं किया जाता।',
          ),
        ),
        _chips(
          _tr('Which languages do you read?', 'आप किन भाषाओं में पढ़ते हैं?'),
          const ['en', 'hi', 'mr'],
          _profile.preferredLanguages,
          (selected) {
            final safe = selected.isEmpty ? const ['en'] : selected;
            final defaultLanguage =
                safe.contains(_profile.defaultReadingLanguage)
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
        _chips(
          _tr('Default reading language', 'पढ़ने की डिफ़ॉल्ट भाषा'),
          _profile.preferredLanguages,
          [_profile.defaultReadingLanguage],
          (selected) => _update(
            _profile.copyWith(defaultReadingLanguage: selected.first),
          ),
          single: true,
        ),
      ],
    );
  }

  Widget _appearance() {
    final background = AccessibilitySettings.previewBg(_profile.colorTheme);
    final foreground = AccessibilitySettings.previewText(_profile.colorTheme);
    final fontExists = AccessibilitySettings.fonts.contains(
      _profile.fontFamily,
    );
    final font = fontExists ? _profile.fontFamily : 'Lexend';
    return Column(
      children: [
        _section(
          _tr('Reading font', 'पढ़ने का फ़ॉन्ट'),
          DropdownButtonFormField<String>(
            value: font,
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
          title: _tr('Text size', 'पाठ का आकार'),
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
          onChanged: (value) =>
              _update(_profile.copyWith(letterSpacing: value)),
        ),
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
          _tr('Background and text contrast', 'पृष्ठभूमि और पाठ का कंट्रास्ट'),
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
        _section(
          _tr('Preview', 'झलक'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: foreground.withOpacity(0.25)),
            ),
            child: Text(
              _tr(
                'A calm space to read, one clear line at a time.',
                'पढ़ने के लिए एक शांत जगह, हर बार एक स्पष्ट पंक्ति।',
              ),
              style: TextStyle(
                fontFamily: font,
                fontSize: _profile.fontSize,
                height: _profile.lineHeight,
                letterSpacing: _profile.letterSpacing,
                wordSpacing: _profile.wordSpacing,
                color: foreground,
              ),
            ),
          ),
        ),
        _section(
          _tr('Reading support', 'पढ़ने में सहायता'),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _tr(
                      'Long sentences are split into shorter reading units by the formatter.',
                      'फ़ॉर्मैटर लंबे वाक्यों को पढ़ने की छोटी इकाइयों में बाँटता है।',
                    ),
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              ),
              _toggle(
                _tr('Simplify difficult words', 'कठिन शब्द सरल करें'),
                _tr(
                  'Choose simplification when preparing a reading.',
                  'पाठ तैयार करते समय सरलीकरण चुनें।',
                ),
                _profile.simplifyText,
                (value) => _update(_profile.copyWith(simplifyText: value)),
              ),
              _toggle(
                _tr(
                  'Highlight words while reading',
                  'पढ़ते समय शब्द हाइलाइट करें',
                ),
                '',
                _profile.wordHighlighting,
                (value) => _update(_profile.copyWith(wordHighlighting: value)),
              ),
              _toggle(
                _tr('Focus line mode', 'फ़ोकस लाइन मोड'),
                '',
                _profile.focusLineMode,
                (value) => _update(_profile.copyWith(focusLineMode: value)),
              ),
              _toggle(
                _tr('Reading ruler', 'रीडिंग रूलर'),
                '',
                _profile.readingRuler,
                (value) => _update(_profile.copyWith(readingRuler: value)),
              ),
              _toggle(
                _tr('Syllable breakdown', 'शब्दांशों में बाँटें'),
                _tr(
                  'Available for supported reading content.',
                  'समर्थित पाठ में उपलब्ध।',
                ),
                _profile.syllableBreakdown,
                (value) => _update(_profile.copyWith(syllableBreakdown: value)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _voiceAndAccess() {
    return Column(
      children: [
        _section(
          _tr('Voice preferences', 'आवाज़ की प्राथमिकताएँ'),
          Column(
            children: [
              _toggle(
                _tr(
                  'Voice assistance by default',
                  'डिफ़ॉल्ट रूप से आवाज़ सहायता',
                ),
                _tr(
                  'Start reading aloud automatically when supported.',
                  'समर्थित होने पर पाठ को अपने आप पढ़ना शुरू करें।',
                ),
                _profile.voiceAssistance,
                (value) => _update(_profile.copyWith(voiceAssistance: value)),
              ),
              _toggle(
                _tr('Highlight spoken words', 'बोले गए शब्द हाइलाइट करें'),
                '',
                _profile.readingHighlight,
                (value) => _update(_profile.copyWith(readingHighlight: value)),
              ),
            ],
          ),
        ),
        _chips(
          _tr('Preferred voice language', 'पसंदीदा आवाज़ की भाषा'),
          const ['en', 'hi', 'mr'],
          [_profile.voiceLanguage],
          (selected) =>
              _update(_profile.copyWith(voiceLanguage: selected.first)),
          single: true,
          helper: _tr(
            'A voice is used only when your device supports that language.',
            'आवाज़ तभी उपयोग होगी जब आपका डिवाइस उस भाषा का समर्थन करे।',
          ),
        ),
        _slider(
          title: _tr('Speech speed', 'बोलने की गति'),
          value: _profile.speechRate,
          min: 0.1,
          max: 1,
          divisions: 9,
          valueText: '${(_profile.speechRate * 100).round()}%',
          onChanged: (value) => _update(_profile.copyWith(speechRate: value)),
        ),
        _section(
          _tr('Display access', 'दृश्य सुलभता'),
          Column(
            children: [
              _toggle(
                _tr('Larger controls', 'बड़े नियंत्रण'),
                '',
                _profile.largerControls,
                (value) => _update(_profile.copyWith(largerControls: value)),
              ),
              _toggle(
                _tr('High contrast', 'ज़्यादा कंट्रास्ट'),
                '',
                _profile.highContrast,
                (value) => _update(_profile.copyWith(highContrast: value)),
              ),
              _toggle(
                _tr('Reduce motion', 'गतिशील प्रभाव कम करें'),
                '',
                _profile.reduceMotion,
                (value) => _update(_profile.copyWith(reduceMotion: value)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _readingGoals() {
    return Column(
      children: [
        _chips(
          _tr('What would you like help with?', 'आप किसमें सहायता चाहते हैं?'),
          const [
            'independent',
            'understanding',
            'study',
            'confidence',
            'multilingual',
          ],
          _profile.readingGoals,
          (selected) => _update(_profile.copyWith(readingGoals: selected)),
        ),
        _chips(
          _tr('What do you usually read?', 'आप आमतौर पर क्या पढ़ते हैं?'),
          const [
            'textbooks',
            'stories',
            'articles',
            'notes',
            'scanned_pages',
            'documents',
          ],
          _profile.materialTypes,
          (selected) => _update(_profile.copyWith(materialTypes: selected)),
        ),
        _chips(
          _tr('Explanation style', 'समझाने का तरीका'),
          const ['shorter_sentences', 'simpler_text', 'word_explanations'],
          [_profile.explanationStyle],
          (selected) =>
              _update(_profile.copyWith(explanationStyle: selected.first)),
          single: true,
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
        _section(
          _tr('Reminders', 'रिमाइंडर'),
          Text(
            _tr(
              'Reading reminders are not scheduled in this version.',
              'इस संस्करण में पढ़ने के रिमाइंडर निर्धारित नहीं होते।',
            ),
            style: const TextStyle(color: AppTheme.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _currentStepContent() => switch (_profile.currentStep) {
    0 => _aboutYou(),
    1 => _readingNeeds(),
    2 => _appearance(),
    3 => _voiceAndAccess(),
    _ => _readingGoals(),
  };

  Widget _backButton(int step) => OutlinedButton(
    onPressed: _finishing ? null : () => _goTo(step - 1),
    child: Text(_tr('Back', 'पीछे')),
  );

  Widget _continueButton(int step, {bool expand = false}) => FilledButton.icon(
    key: ValueKey(step == 4 ? 'onboarding-finish' : 'onboarding-next'),
    style: FilledButton.styleFrom(
      minimumSize: Size(expand ? double.infinity : 136, 52),
    ),
    onPressed: _finishing
        ? null
        : step == 4
        ? _finish
        : () => _goTo(step + 1),
    icon: _finishing
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(step == 4 ? Icons.check_rounded : Icons.arrow_forward_rounded),
    label: Text(
      _finishing
          ? _tr('Saving…', 'सहेज रहे हैं…')
          : step == 4
          ? _tr('Finish', 'पूरा करें')
          : _tr('Continue', 'आगे बढ़ें'),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final step = _profile.currentStep.clamp(0, 4).toInt();
    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          _tr('Personalise your reading', 'अपना पढ़ने का अनुभव बनाएँ'),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _tr('Step ${step + 1} of 5', 'चरण ${step + 1} / 5'),
                            style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _tr(
                              'Your answers save as you go',
                              'आपके जवाब साथ-साथ सहेजे जाते हैं',
                            ),
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (step + 1) / 5,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(10),
                        backgroundColor: AppTheme.lightGrey,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _tr(
                          _stepTitles[step],
                          const [
                            'आपके बारे में',
                            'पढ़ने की ज़रूरतें',
                            'पढ़ने का रूप',
                            'आवाज़ और सुलभता',
                            'पढ़ने के लक्ष्य',
                          ][step],
                        ),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    key: ValueKey('onboarding-step-$step'),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Column(
                      children: [
                        _currentStepContent(),
                        if (_saveError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              children: [
                                Text(
                                  _saveError!,
                                  style: const TextStyle(color: AppTheme.error),
                                  textAlign: TextAlign.center,
                                ),
                                if (kDebugMode && _saveDiagnostics != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: SelectableText(
                                      _saveDiagnostics!,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
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
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 400 || step == 4;
                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (step > 0) ...[
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _backButton(step),
                              ),
                              const SizedBox(height: 8),
                            ],
                            _continueButton(step, expand: true),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          if (step > 0) _backButton(step),
                          if (step > 0) const SizedBox(width: 10),
                          if (step > 0 && step < 4)
                            TextButton(
                              onPressed: _finishing
                                  ? null
                                  : () => _goTo(step + 1),
                              child: Text(
                                _tr('Skip optional', 'वैकल्पिक छोड़ें'),
                              ),
                            ),
                          const Spacer(),
                          _continueButton(step),
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
    );
  }
}
