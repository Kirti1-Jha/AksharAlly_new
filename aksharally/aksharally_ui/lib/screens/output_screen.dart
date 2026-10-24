import 'dart:async';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/library_storage.dart';
import '../models/library_item.dart';
import '../models/format_result.dart';
import '../services/reading_text_segments.dart';
import '../services/tts_progress_mapper.dart';
import '../services/tts_service.dart';
import '../services/voice_command_handler.dart';
import '../theme/app_settings.dart';
import '../theme/accessibility_settings.dart';
import '../widgets/highlighted_text_view.dart';
import '../widgets/structured_content_view.dart';
import '../widgets/reading_customize_sheet.dart';
import '../widgets/voice_assistant_controls.dart';

/// OutputScreen — DISPLAY / READING screen only.
///
/// OutputScreen never performs input processing. All OCR and AI
/// (Gemini) calls happen upstream in ReadingScreen; by the time content
/// reaches this screen it is already final. This screen's only job is to
/// render that content in a dyslexia-friendly way and provide reading
/// controls (TTS, word highlighting, accessibility/profile settings,
/// library save/open).
///
/// Content can arrive from three sources, all already processed:
///   - ReadingScreen  → initialFormatResult (OCR/format-only result)
///   - ReadingScreen  → displayText (typed text, or OCR+Gemini result)
///   - LibraryScreen  → displayText (previously-saved content)
///   - initialText is kept only for backward-compatible construction and
///     is displayed as-is — OutputScreen never calls Gemini itself.
///
/// ReaderScreen itself is left completely untouched as rollback
/// protection — it is simply no longer referenced by navigation.
class OutputScreen extends StatefulWidget {
  /// Kept for constructor compatibility. Nothing currently passes this,
  /// but if it is ever provided, the text is displayed directly —
  /// OutputScreen never calls the AI simplify endpoint itself.
  final String? initialText;

  /// Pre-formatted result from ReadingScreen (image/file, Format Only).
  final FormatResult? initialFormatResult;

  /// Already-processed / already-saved text — from ReadingScreen (typed
  /// text, or OCR+Gemini result) or from LibraryScreen (saved content).
  final String? displayText;

  /// When true, _loadDisplayText() saves the content to the library.
  /// Set to true only by ReadingScreen (fresh content).
  /// LibraryScreen and HomeScreen leave this false to avoid duplicates.
  final bool saveOnLoad;

  const OutputScreen({
    super.key,
    this.initialText,
    this.initialFormatResult,
    this.displayText,
    this.saveOnLoad = false,
  });

  @override
  State<OutputScreen> createState() => _OutputScreenState();
}

class _OutputScreenState extends State<OutputScreen> {
  // ── display text state ────────────────────────────────────────────────────
  String simplifiedText = '';

  // ── profile & format result ───────────────────────────────────────────────
  // _selectedProfile reflects the active accessibility preset.
  // _isCustomize tracks whether the 'Customize' chip is visually active.
  String _selectedProfile = 'moderate';
  bool _isCustomize = false;
  bool _showOriginalOcr = false;
  FormatResult? _formatResult;

  // ── TTS ───────────────────────────────────────────────────────────────────
  final TTSService _tts = TTSService();
  double speechRate = AppSettings.speechRate;
  double _playbackSpeed = TTSService.playbackSpeedForEngineRate(
    AppSettings.speechRate,
  );
  bool autoRead = true;
  bool _isPlaybackStarting = false;
  bool _isPlaybackActive = false;
  bool _isPlaybackPaused = false;
  bool _hasPreciseProgress = false;
  bool _fallbackMode = false;
  int _playbackSession = 0;
  String? _voiceCommandFeedback;
  bool _resumeReadingAfterVoiceInput = false;
  List<int> _activeSpeechWordIndices = const [];
  TtsProgressMapper? _progressMapper;

  List<String> words = [];
  int currentIndex = -1;
  Timer? _timer;
  Timer? _progressWatchdog;

  // ── accessibility overlays ────────────────────────────────────────────────
  // Initialised lazily in build() once LayoutBuilder provides a real height.
  double? _focusLineY; // centre of the focus band
  double? _rulerY; // top edge of the reading ruler

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _playbackSpeed = TTSService.playbackSpeedForEngineRate(speechRate);
    speechRate = TTSService.engineRateForPlaybackSpeed(_playbackSpeed);
    AppSettings.speechRate = speechRate;
    _tts.init(
      defaultLocale: TTSService.localeForLanguage(AppSettings.language),
    );

    // Restore active profile from persisted accessibility settings.
    _selectedProfile = (AccessibilitySettings.profile == 'customize')
        ? 'moderate'
        : AccessibilitySettings.profile;
    _isCustomize = AccessibilitySettings.profile == 'customize';

    if (widget.initialFormatResult != null) {
      // Pre-formatted result from ReadingScreen (image/file, format-only).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialFormatResult(widget.initialFormatResult!);
      });
    } else if (widget.displayText != null) {
      // Already-processed / already-saved content — display as-is,
      // no API call.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDisplayText(widget.displayText!);
      });
    } else if (widget.initialText != null) {
      // Compatibility path only — display as-is. OutputScreen never
      // calls the AI simplify endpoint itself.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDisplayText(widget.initialText!);
      });
    }
  }

  // ── word-splitting — removes embedded \n / \n\n ───────────────────────────
  List<String> _splitToWords(String text) =>
      HighlightedTextView.splitToWords(text);

  // ── load pre-formatted result (from ReadingScreen) ────────────────────────
  void _loadInitialFormatResult(FormatResult r) {
    setState(() {
      _formatResult = r;
      simplifiedText = r.processedText;
      words = _splitToWords(r.processedText);
    });
    _saveToLibrary(r.processedText, r.sourceType);
    if (autoRead) startReading();
  }

  // ── load already-processed / already-saved text — no API call ────────────
  void _loadDisplayText(String text) {
    setState(() {
      simplifiedText = text;
      words = _splitToWords(text);
    });
    // Save only when the caller (ReadingScreen) signals fresh content via
    // saveOnLoad: true. LibraryScreen and HomeScreen leave saveOnLoad at its
    // default (false), so reopening existing items never creates duplicates.
    if (widget.saveOnLoad) _saveToLibrary(text, 'text');
    if (autoRead) startReading();
  }

  // ── library save ──────────────────────────────────────────────────────────
  void _saveToLibrary(String content, String sourceType) {
    if (content.isEmpty || content.startsWith('❌') || content.startsWith('⚠️'))
      return;

    final wordCount = content.split(' ').where((w) => w.isNotEmpty).length;
    final now = DateTime.now();
    final label = sourceType.isEmpty ? 'Document' : _cap(sourceType);

    LibraryStorage.addItem(
      LibraryItem(
        title: '$label · ${wordCount}w · ${now.day}/${now.month}/${now.year}',
        content: content,
        date: now,
        sourceType: sourceType,
      ),
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  // ── accessibility theme helpers ───────────────────────────────────────────
  Color getBackgroundColor() => AccessibilitySettings.backgroundColor();
  Color getTextColor() => AccessibilitySettings.textColor();

  // ── TTS ───────────────────────────────────────────────────────────────────
  List<int> get _spokenDisplayWordIndices => [
    for (var index = 0; index < words.length; index++)
      if (words[index] != HighlightedTextView.paragraphMarker &&
          words[index] != HighlightedTextView.lineBreakMarker)
        index,
  ];

  Future<void> startReading() async {
    if (simplifiedText.isEmpty) return;
    await _speakUtterance(simplifiedText, _spokenDisplayWordIndices);
  }

  Future<void> _speakUtterance(
    String text,
    List<int> displayWordIndices,
  ) async {
    if (text.trim().isEmpty || displayWordIndices.isEmpty) return;
    final session = ++_playbackSession;
    _timer?.cancel();
    _progressWatchdog?.cancel();
    final mapper = TtsProgressMapper(
      text: text,
      displayWordIndices: displayWordIndices,
      displayWords: [for (final index in displayWordIndices) words[index]],
    );
    _activeSpeechWordIndices = List<int>.from(displayWordIndices);
    _progressMapper = mapper;
    _hasPreciseProgress = false;
    _fallbackMode = false;
    if (mounted) {
      setState(() {
        currentIndex = displayWordIndices.first;
        _isPlaybackStarting = true;
        _isPlaybackActive = false;
        _isPlaybackPaused = false;
      });
    }

    await _tts.init(
      defaultLocale: TTSService.localeForLanguage(AppSettings.language),
    );
    if (!_isCurrentPlaybackSession(session)) return;

    // Invalidate any previous utterance before setting its rate. This keeps a
    // rapid Start/Resume sequence from restarting old speech or overlapping it.
    await _tts.stop();
    if (!_isCurrentPlaybackSession(session)) return;
    await _tts.setRate(speechRate);
    if (!_isCurrentPlaybackSession(session)) return;
    await _tts.speak(
      text,
      onStart: () {
        if (!_isCurrentPlaybackSession(session)) return;
        setState(() {
          _isPlaybackStarting = false;
          _isPlaybackActive = true;
          _isPlaybackPaused = false;
        });
        _scheduleProgressWatchdog(session);
      },
      onProgress: (_, start, end, word) {
        if (!_isCurrentPlaybackSession(session) ||
            !identical(_progressMapper, mapper) ||
            _tts.isPaused) {
          return;
        }
        if (mapper.isCoarseProgressRange(word, start, end)) {
          _fallbackMode = true;
          _progressWatchdog?.cancel();
          _startFallbackHighlightTimer(session);
          return;
        }
        final wasUsingFallback = _fallbackMode;
        _hasPreciseProgress = true;
        _fallbackMode = false;
        _progressWatchdog?.cancel();
        _timer?.cancel();
        final displayIndex = mapper.displayIndexForRange(start, end);
        if (displayIndex == null ||
            (displayIndex < currentIndex && !wasUsingFallback)) {
          return;
        }
        if (displayIndex != currentIndex) {
          setState(() => currentIndex = displayIndex);
        }
      },
      onComplete: () {
        if (!_isCurrentPlaybackSession(session)) return;
        _finishPlaybackSession();
      },
      onError: (_) {
        if (!_isCurrentPlaybackSession(session)) return;
        _finishPlaybackSession();
      },
    );
    // Some platform engines return from speak() before dispatching their
    // start event. Keep controls responsive and retain the no-progress
    // fallback for engines that do not provide word-boundary callbacks.
    if (_isCurrentPlaybackSession(session) &&
        _tts.isSpeaking &&
        _isPlaybackStarting) {
      setState(() {
        _isPlaybackStarting = false;
        _isPlaybackActive = true;
      });
      _scheduleProgressWatchdog(session);
    }
  }

  bool _isCurrentPlaybackSession(int session) =>
      mounted && session == _playbackSession;

  void _finishPlaybackSession() {
    _timer?.cancel();
    setState(() {
      currentIndex = -1;
      _isPlaybackStarting = false;
      _isPlaybackActive = false;
      _isPlaybackPaused = false;
    });
    _activeSpeechWordIndices = const [];
    _progressMapper = null;
    _hasPreciseProgress = false;
  }

  void _startFallbackHighlightTimer(int session) {
    _timer?.cancel();
    if (!_isCurrentPlaybackSession(session) ||
        !_isPlaybackActive ||
        _isPlaybackPaused ||
        _hasPreciseProgress) {
      return;
    }
    final mapper = _progressMapper;
    if (!mounted || currentIndex < 0 || mapper == null) return;

    final currentPosition = mapper.positionForDisplayIndex(currentIndex);
    if (currentPosition == null) return;
    final currentWords = mapper.wordsForDisplayIndex(currentIndex);
    if (currentWords.isEmpty) return;

    final nextIndex = _activeSpeechWordIndices.indexWhere(
      (index) => index > currentIndex,
    );
    if (nextIndex < 0) return;

    _timer = Timer(
      currentWords.fold<Duration>(
        Duration.zero,
        (total, word) =>
            total + TtsProgressMapper.estimateWordDuration(word, speechRate),
      ),
      () {
        if (!_isCurrentPlaybackSession(session) ||
            !_isPlaybackActive ||
            _isPlaybackPaused ||
            _tts.isPaused ||
            _hasPreciseProgress) {
          return;
        }
        final nextDisplayIndex = _activeSpeechWordIndices[nextIndex];
        setState(() => currentIndex = nextDisplayIndex);

        final nextPosition = mapper.positionForDisplayIndex(nextDisplayIndex);
        final sourceOffset = nextPosition == null
            ? null
            : mapper.sourceOffsetAtPosition(nextPosition);
        if (sourceOffset != null) _tts.setFallbackResumeOffset(sourceOffset);
        _startFallbackHighlightTimer(session);
      },
    );
  }

  Future<void> stopReading() async {
    final session = ++_playbackSession;
    _timer?.cancel();
    if (mounted) {
      setState(() {
        currentIndex = -1;
        _isPlaybackStarting = false;
        _isPlaybackActive = false;
        _isPlaybackPaused = false;
      });
    }
    _activeSpeechWordIndices = const [];
    _progressMapper = null;
    _hasPreciseProgress = false;
    await _tts.stop();
    if (!_isCurrentPlaybackSession(session)) return;
  }

  Future<void> _pauseReading() async {
    final session = _playbackSession;
    final paused = await _tts.pause();
    if (!_isCurrentPlaybackSession(session)) return;
    if (paused) {
      _timer?.cancel();
      setState(() {
        _isPlaybackPaused = true;
        _isPlaybackActive = true;
      });
    } else if (!_hasPreciseProgress) {
      _startFallbackHighlightTimer(session);
    }
  }

  Future<void> _resumeReading() async {
    final session = _playbackSession;
    if (!_tts.isPaused) {
      if (!_tts.isSpeaking && !_isPlaybackStarting) {
        await startReading();
      }
      return;
    }
    if (await _tts.resume() && _isCurrentPlaybackSession(session)) {
      setState(() {
        _isPlaybackStarting = false;
        _isPlaybackActive = true;
        _isPlaybackPaused = false;
      });
      _startFallbackHighlightTimer(session);
    }
  }

  Future<void> _setPlaybackSpeed(double speed) async {
    if (!TTSService.playbackSpeeds.contains(speed)) return;
    final session = _playbackSession;
    final newRate = TTSService.engineRateForPlaybackSpeed(speed);
    setState(() {
      _playbackSpeed = speed;
      speechRate = newRate;
      AppSettings.speechRate = newRate;
    });
    await _tts.setRate(newRate);
    if (!_isCurrentPlaybackSession(session)) return;
    if (_tts.isPaused || _isPlaybackPaused) {
      _timer?.cancel();
    } else {
      _startFallbackHighlightTimer(session);
    }
  }

  Future<void> _prepareForVoiceInput() async {
    _resumeReadingAfterVoiceInput = _tts.isSpeaking || _tts.isPaused;
    if (_tts.isSpeaking) await _pauseReading();
    _timer?.cancel();
  }

  Future<void> _restoreReadingAfterVoiceInput() async {
    if (!_resumeReadingAfterVoiceInput) return;
    _resumeReadingAfterVoiceInput = false;
    await _resumeReading();
  }

  Future<void> _handleVoiceCommand(
    String transcript,
    String languageCode,
  ) async {
    final intent = VoiceCommandHandler.parse(
      transcript,
      languageCode: languageCode,
    );
    var feedback = 'Command completed.';

    switch (intent) {
      case VoiceCommandIntent.readCurrentPage:
        _resumeReadingAfterVoiceInput = false;
        await startReading();
        feedback = 'Reading started.';
      case VoiceCommandIntent.pauseReading:
        _resumeReadingAfterVoiceInput = false;
        await _pauseReading();
        feedback = 'Reading paused.';
      case VoiceCommandIntent.resumeReading:
        _resumeReadingAfterVoiceInput = false;
        await _resumeReading();
        feedback = 'Reading resumed.';
      case VoiceCommandIntent.stopReading:
        _resumeReadingAfterVoiceInput = false;
        await stopReading();
        feedback = 'Reading stopped.';
      case VoiceCommandIntent.repeatSentence:
        final activeIndex = currentIndex < 0 ? 0 : currentIndex;
        final range = ReadingTextSegments.sentenceAt(words, activeIndex);
        if (range == null) {
          feedback = 'There is no sentence to repeat.';
        } else {
          _resumeReadingAfterVoiceInput = false;
          final displayIndices = [
            for (
              var index = range.firstWordIndex;
              index <= range.lastWordIndex;
              index++
            )
              if (words[index] != HighlightedTextView.paragraphMarker &&
                  words[index] != HighlightedTextView.lineBreakMarker)
                index,
          ];
          final sentence = displayIndices
              .map((index) => words[index])
              .join(' ');
          await _speakUtterance(sentence, displayIndices);
          feedback = 'Repeating the current sentence.';
        }
      case VoiceCommandIntent.repeatPassage:
        _resumeReadingAfterVoiceInput = false;
        await _speakUtterance(simplifiedText, _spokenDisplayWordIndices);
        feedback = 'Repeating the passage.';
      case VoiceCommandIntent.increaseSpeechRate:
      case VoiceCommandIntent.decreaseSpeechRate:
        final speedIndex = TTSService.playbackSpeeds.indexOf(_playbackSpeed);
        final direction = intent == VoiceCommandIntent.increaseSpeechRate
            ? 1
            : -1;
        final nextIndex = (speedIndex + direction)
            .clamp(0, TTSService.playbackSpeeds.length - 1)
            .toInt();
        _playbackSpeed = TTSService.playbackSpeeds[nextIndex];
        speechRate = TTSService.engineRateForPlaybackSpeed(_playbackSpeed);
        AppSettings.speechRate = speechRate;
        await _tts.setRate(speechRate);
        await _restoreReadingAfterVoiceInput();
        feedback = 'Reading speed updated.';
      case VoiceCommandIntent.increaseFontSize:
      case VoiceCommandIntent.decreaseFontSize:
        final adjustment = intent == VoiceCommandIntent.increaseFontSize
            ? 2.0
            : -2.0;
        AccessibilitySettings.fontSize =
            (AccessibilitySettings.fontSize + adjustment)
                .clamp(12.0, 48.0)
                .toDouble();
        AccessibilitySettings.profile = 'customize';
        _isCustomize = true;
        await AccessibilitySettings.save();
        await _restoreReadingAfterVoiceInput();
        feedback = 'Text size updated.';
      case VoiceCommandIntent.changeColors:
        final themes = AccessibilitySettings.themeLabels.keys.toList();
        final currentTheme = themes.indexOf(AccessibilitySettings.colorTheme);
        AccessibilitySettings.colorTheme =
            themes[(currentTheme + 1) % themes.length];
        AccessibilitySettings.profile = 'customize';
        _isCustomize = true;
        await AccessibilitySettings.save();
        await _restoreReadingAfterVoiceInput();
        feedback = 'Reading colors updated.';
      case VoiceCommandIntent.unsupported:
        feedback = VoiceCommandHandler.unsupportedFeedback(languageCode);
        await _restoreReadingAfterVoiceInput();
    }

    if (mounted) setState(() => _voiceCommandFeedback = feedback);
  }

  Future<void> _setVoiceLanguage(String languageCode, String localeId) async {
    await AppSettings.saveVoiceLanguagePreference(
      languageCode,
      localeId: localeId,
    );
  }

  @override
  void dispose() {
    ++_playbackSession;
    _timer?.cancel();
    _tts.stop();
    super.dispose();
  }

  // ── profile chip selector ─────────────────────────────────────────────────
  Widget _profileSelector() {
    const presets = ['mild', 'moderate', 'severe'];
    // Active chip is 'customize' if _isCustomize, else _selectedProfile.
    final activeChip = _isCustomize ? 'customize' : _selectedProfile;

    // Larger Touch Targets: increase chip hit area when the toggle is on.
    final chipPadH = AccessibilitySettings.largerTouchTargets ? 20.0 : 14.0;
    final chipPadV = AccessibilitySettings.largerTouchTargets ? 12.0 : 8.0;

    Widget chip(String value, {IconData? icon}) {
      final isSelected = activeChip == value;
      final label = '${value[0].toUpperCase()}${value.substring(1)}';
      return Semantics(
        button: true,
        selected: isSelected,
        label: '$label reading profile',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            onTap: () => _onProfileChanged(value),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              padding: EdgeInsets.symmetric(
                horizontal: chipPadH,
                vertical: chipPadV,
              ),
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.brandGradient : null,
                color: isSelected ? null : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 14,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final p in presets) chip(p),
        chip('customize', icon: Icons.tune),
      ],
    );
  }

  // ── profile changed ───────────────────────────────────────────────────────
  Future<void> _onProfileChanged(String profile) async {
    if (profile == 'customize') {
      // Customize is purely client-side.
      setState(() => _isCustomize = true);
      AccessibilitySettings.profile = 'customize';
      await showReadingCustomizeSheet(
        context,
        onChanged: () {
          if (mounted) setState(() {});
        },
        detectedText: words.join(' '),
      );
      return;
    }

    // Preset selected — apply client-side accessibility settings.
    AccessibilitySettings.applyPreset(profile);
    setState(() {
      _selectedProfile = profile;
      _isCustomize = false;
    });
    await AccessibilitySettings.save();
  }

  // ── formatting info bar ───────────────────────────────────────────────────
  Widget _formattingInfoBar() {
    final activeProfile = _isCustomize ? 'customize' : _selectedProfile;
    final font = AccessibilitySettings.fontFamily == 'Atkinson Hyperlegible'
        ? 'Atkinson'
        : AccessibilitySettings.fontFamily;
    final theme =
        AccessibilitySettings.themeLabels[AccessibilitySettings.colorTheme] ??
        'Custom';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.accentCream.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.15)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _infoBadge('Profile', _cap(activeProfile)),
          _infoBadge('Font', font),
          _infoBadge(
            'Size',
            '${AccessibilitySettings.fontSize.toStringAsFixed(0)}px',
          ),
          _infoBadge(
            'Letter',
            '${AccessibilitySettings.letterSpacing.toStringAsFixed(1)}',
          ),
          _infoBadge(
            'Word',
            '${AccessibilitySettings.wordSpacing.toStringAsFixed(1)}px',
          ),
          _infoBadge(
            'Line',
            '${AccessibilitySettings.lineHeight.toStringAsFixed(1)}×',
          ),
          _infoBadge(
            'Para',
            '${AccessibilitySettings.paragraphSpacing.toStringAsFixed(0)}px',
          ),
          _infoBadge('Theme', theme),
        ],
      ),
    );
  }

  Widget _infoBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── primary (blue gradient) button — Start / Stop ─────────────────────────
  Widget _primaryButton(String text, VoidCallback onTap, {IconData? icon}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white),
                const SizedBox(width: 6),
              ],
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playbackToggleButton() {
    final isPaused = _isPlaybackPaused;
    final canToggle = _isPlaybackActive || isPaused;
    return OutlinedButton.icon(
      onPressed: canToggle
          ? () => isPaused ? _resumeReading() : _pauseReading()
          : null,
      icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
      label: Text(isPaused ? 'Resume' : 'Pause'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primaryBlue,
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.55)),
      ),
    );
  }

  Widget _playbackSpeedSelector() {
    String labelFor(double speed) =>
        '${speed.toStringAsFixed(speed == speed.roundToDouble() ? 1 : 2)}x';

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Playback speed',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<double>(
          value: _playbackSpeed,
          isExpanded: true,
          onChanged: (speed) {
            if (speed != null) _setPlaybackSpeed(speed);
          },
          items: [
            for (final speed in TTSService.playbackSpeeds)
              DropdownMenuItem(value: speed, child: Text(labelFor(speed))),
          ],
        ),
      ),
    );
  }

  // ── empty state — no content was provided to this screen ─────────────────
  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 44,
            color: AppTheme.primaryBlue.withOpacity(0.35),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            'Nothing to read yet',
            style: AppTheme.titleStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            'Go back and scan, type, or upload some content first.',
            style: AppTheme.captionStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceLG),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
              label: const Text(
                'Go Back',
                style: TextStyle(color: AppTheme.primaryBlue),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── reading card — the formatted/simplified content ───────────────────────
  Widget _readingCard() {
    final structuredBlocks =
        _formatResult?.structuredContent?['blocks'] as List?;
    final hasStructuredLayout =
        structuredBlocks?.any(
          (block) => block is Map && block['type'] != 'paragraph',
        ) ??
        false;
    final originalText = _formatResult?.originalText;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        decoration: BoxDecoration(
          color: getBackgroundColor(),
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasStructuredLayout)
              StructuredContentView(
                content: _formatResult!.structuredContent!,
                words: words,
                currentIndex: currentIndex,
              )
            else
              HighlightedTextView(
                text: simplifiedText,
                words: words,
                currentIndex: currentIndex,
              ),
            if (originalText != null && originalText.trim().isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceMD),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 4),
                title: Text(
                  'View original OCR',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                initiallyExpanded: _showOriginalOcr,
                onExpansionChanged: (expanded) =>
                    setState(() => _showOriginalOcr = expanded),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(
                      originalText,
                      style: TextStyle(
                        color: getTextColor().withOpacity(0.82),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Focus Line Mode overlay ───────────────────────────────────────────────
  //
  // Dims content above and below a draggable horizontal band.
  // The dimming rectangles use IgnorePointer so they never block
  // scrolling or text interaction. Only the drag handle absorbs events.
  Widget _focusLineOverlay(double bodyHeight) {
    const bandH = 72.0;
    final fy = (_focusLineY ?? bodyHeight * 0.45).clamp(
      bandH / 2,
      bodyHeight - bandH / 2,
    );
    final bandTop = fy - bandH / 2;

    return Stack(
      children: [
        // ── Upper dim ──────────────────────────────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: bandTop,
          child: IgnorePointer(
            child: Container(color: Colors.black.withOpacity(0.30)),
          ),
        ),
        // ── Lower dim ──────────────────────────────────────────────────────
        Positioned(
          top: bandTop + bandH,
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(color: Colors.black.withOpacity(0.30)),
          ),
        ),
        // ── Top border of focus band ───────────────────────────────────────
        Positioned(
          top: bandTop,
          left: 0,
          right: 0,
          height: 2,
          child: IgnorePointer(
            child: Container(color: AppTheme.primaryBlue.withOpacity(0.75)),
          ),
        ),
        // ── Bottom border of focus band ────────────────────────────────────
        Positioned(
          top: bandTop + bandH - 2,
          left: 0,
          right: 0,
          height: 2,
          child: IgnorePointer(
            child: Container(color: AppTheme.primaryBlue.withOpacity(0.75)),
          ),
        ),
        // ── Drag handle — only interactive element ─────────────────────────
        Positioned(
          top: bandTop + (bandH / 2) - 16,
          right: 10,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (d) => setState(() {
              _focusLineY = (fy + d.delta.dy).clamp(
                bandH / 2,
                bodyHeight - bandH / 2,
              );
            }),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.swap_vert, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  // ── Reading Ruler overlay ─────────────────────────────────────────────────
  //
  // A thin horizontal guide line the user can drag freely. The line itself
  // is IgnorePointer so it never blocks scrolling; only the circular handle
  // on the right absorbs pan events.
  Widget _readingRulerOverlay(double bodyHeight) {
    final ry = (_rulerY ?? bodyHeight * 0.3).clamp(4.0, bodyHeight - 4.0);

    return Stack(
      children: [
        // ── Ruler line ─────────────────────────────────────────────────────
        Positioned(
          top: ry,
          left: 0,
          right: 48,
          height: 3,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.80),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.30),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
        // ── Drag handle ────────────────────────────────────────────────────
        Positioned(
          top: ry - 16,
          right: 10,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (d) => setState(() {
              _rulerY = (ry + d.delta.dy).clamp(4.0, bodyHeight - 4.0);
            }),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.drag_indicator,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final hasContent = simplifiedText.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.creamGradient),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.brandGradient.createShader(bounds),
          child: const Text(
            'AksharAlly',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
      ),

      // LayoutBuilder gives us the real body height so the overlay
      // positions (focus band, reading ruler) can be initialised and
      // clamped correctly.
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Lazy initialisation — set once per session, then user can drag.
          _focusLineY ??= constraints.maxHeight * 0.45;
          _rulerY ??= constraints.maxHeight * 0.30;

          return Stack(
            children: [
              // ── Scrollable reading content ─────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                child: ListView(
                  children: [
                    // ── PROFILE SELECTOR ──────────────────────────────────
                    _profileSelector(),

                    const SizedBox(height: AppTheme.spaceSM),

                    // ── FORMATTING INFO BAR ───────────────────────────────
                    _formattingInfoBar(),

                    const SizedBox(height: AppTheme.spaceMD),

                    if (!hasContent) ...[
                      _emptyState(),
                    ] else ...[
                      // ── START / STOP ─────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _primaryButton(
                              'Start',
                              startReading,
                              icon: Icons.play_arrow,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceSM),
                          Expanded(
                            child: _primaryButton(
                              'Stop',
                              stopReading,
                              icon: Icons.stop,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppTheme.spaceSM),

                      Row(
                        children: [
                          Expanded(child: _playbackToggleButton()),
                          const SizedBox(width: AppTheme.spaceSM),
                          Expanded(child: _playbackSpeedSelector()),
                        ],
                      ),

                      const SizedBox(height: AppTheme.spaceMD),

                      // ── AUTO READ SWITCH ──────────────────────────────────
                      SwitchListTile(
                        title: Text(
                          'Auto Read',
                          style: TextStyle(color: getTextColor()),
                        ),
                        value: autoRead,
                        onChanged: (v) => setState(() => autoRead = v),
                      ),

                      if (AppSettings.voiceAssistanceEnabled) ...[
                        const SizedBox(height: AppTheme.spaceMD),
                        VoiceAssistantControls(
                          initialLanguageCode: AppSettings.voiceLanguage,
                          initialLocaleId: AppSettings.voiceLocaleId,
                          onBeforeListening: _prepareForVoiceInput,
                          onRecognized: _handleVoiceCommand,
                          onListeningCancelled: _restoreReadingAfterVoiceInput,
                          onLanguageChanged: _setVoiceLanguage,
                          feedback: _voiceCommandFeedback,
                        ),
                      ],

                      const SizedBox(height: AppTheme.spaceMD),

                      // ── READING CARD ──────────────────────────────────────
                      _readingCard(),
                    ],
                  ],
                ),
              ),

              // ── Accessibility overlays (above scroll, non-blocking) ─────
              // Focus Line Mode: dims content above/below a draggable band.
              // Reduce Motion: overlays appear/disappear instantly (no
              // animation) — already the case since we use `if` not
              // AnimatedSwitcher.
              if (AccessibilitySettings.focusLineMode)
                _focusLineOverlay(constraints.maxHeight),

              // Reading Ruler: a draggable horizontal guide line.
              if (AccessibilitySettings.readingRuler)
                _readingRulerOverlay(constraints.maxHeight),
            ],
          );
        },
      ),
    );
  }
}
