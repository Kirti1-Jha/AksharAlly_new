import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceAssistantControls extends StatefulWidget {
  const VoiceAssistantControls({
    super.key,
    required this.initialLanguageCode,
    required this.onBeforeListening,
    required this.onRecognized,
    required this.onListeningCancelled,
    required this.onLanguageChanged,
    this.feedback,
  });

  final String? initialLanguageCode;
  final Future<void> Function() onBeforeListening;
  final Future<void> Function(String transcript, String languageCode)
  onRecognized;
  final Future<void> Function() onListeningCancelled;
  final Future<void> Function(String languageCode, String localeId)
  onLanguageChanged;
  final String? feedback;

  @override
  State<VoiceAssistantControls> createState() => _VoiceAssistantControlsState();
}

class _VoiceAssistantControlsState extends State<VoiceAssistantControls> {
  final SpeechToText _speech = SpeechToText();

  List<LocaleName> _supportedLocales = const [];
  String? _selectedLocaleId;
  String _message = 'Tap the microphone to give a reading command.';
  String _transcript = '';
  bool _preparing = false;
  bool _available = false;
  bool _isListening = false;
  bool _sessionOpen = false;
  bool _handledFinalResult = false;

  @override
  void dispose() {
    if (_sessionOpen || _isListening) {
      unawaited(_cancelSpeechOnDispose());
    }
    super.dispose();
  }

  Future<void> _cancelSpeechOnDispose() async {
    try {
      await _speech.cancel();
    } catch (_) {
      // The platform session may already have ended while this widget closes.
    }
  }

  @override
  void didUpdateWidget(covariant VoiceAssistantControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLanguageCode != widget.initialLanguageCode &&
        _supportedLocales.isNotEmpty &&
        !_isListening) {
      _selectInitialLocale();
    }
  }

  Future<bool> _prepareSpeech() async {
    if (_available) return true;
    if (_preparing) return false;

    setState(() {
      _preparing = true;
      _message = 'Checking microphone and speech-recognition access…';
    });

    try {
      final initialized = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
      );
      if (!initialized) {
        if (mounted) {
          setState(() {
            _available = false;
            _message =
                'Speech recognition is unavailable. Check microphone and speech permissions in device settings.';
          });
        }
        return false;
      }

      final deviceLocales = await _speech.locales();
      final supported =
          deviceLocales
              .where((locale) => _languageForLocale(locale.localeId) != null)
              .toList()
            ..sort((a, b) {
              final languageOrder = _languageForLocale(
                a.localeId,
              )!.compareTo(_languageForLocale(b.localeId)!);
              return languageOrder != 0
                  ? languageOrder
                  : a.name.compareTo(b.name);
            });

      if (!mounted) return false;
      setState(() {
        _available = true;
        _supportedLocales = supported;
        _message = supported.isEmpty
            ? 'This device does not list English, Hindi, or Marathi speech recognition.'
            : 'Choose a command language supported by this device.';
      });
      _selectInitialLocale();
      return true;
    } catch (error) {
      if (mounted) {
        setState(() {
          _message = 'Could not start speech recognition: $error';
        });
      }
      return false;
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  void _selectInitialLocale() {
    final preferred = _baseLanguage(widget.initialLanguageCode);
    if (preferred == null) {
      setState(() {
        _selectedLocaleId = null;
        _message = _supportedLocales.isEmpty
            ? 'This device does not list English, Hindi, or Marathi speech recognition.'
            : 'Choose a command language supported by this device.';
      });
      return;
    }

    final matches = _supportedLocales
        .where((locale) => _languageForLocale(locale.localeId) == preferred)
        .toList();
    if (matches.isEmpty) {
      setState(() {
        _selectedLocaleId = null;
        _message =
            'No ${_languageName(preferred)} speech-recognition locale is available. Select a listed language; AksharAlly will not switch languages automatically.';
      });
      return;
    }

    final selected = matches.first;
    setState(() {
      _selectedLocaleId = selected.localeId;
      _message = 'Voice commands use ${selected.name}.';
    });
    unawaited(widget.onLanguageChanged(preferred, selected.localeId));
  }

  Future<void> _selectLocale(String localeId) async {
    final languageCode = _languageForLocale(localeId);
    if (languageCode == null) return;
    final locale = _supportedLocales.firstWhere(
      (item) => item.localeId == localeId,
    );
    setState(() {
      _selectedLocaleId = localeId;
      _message = 'Voice commands use ${locale.name}.';
    });
    await widget.onLanguageChanged(languageCode, localeId);
  }

  Future<void> _toggleListening() async {
    if (_sessionOpen && !_isListening) return;
    if (_isListening) {
      await _cancelListening();
      return;
    }
    if (_preparing) return;
    if (!await _prepareSpeech()) return;

    final localeId = _selectedLocaleId;
    final languageCode = localeId == null ? null : _languageForLocale(localeId);
    if (localeId == null || languageCode == null) {
      setState(() {
        _message = _supportedLocales.isEmpty
            ? 'No supported speech-recognition language is available on this device.'
            : 'Select a voice-command language before listening.';
      });
      return;
    }

    await widget.onBeforeListening();
    if (!mounted) return;

    setState(() {
      _transcript = '';
      _message = 'Listening…';
      _sessionOpen = true;
      _handledFinalResult = false;
      _isListening = true;
    });

    try {
      await _speech.listen(
        onResult: (result) => _handleResult(result, languageCode),
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenMode: ListenMode.confirmation,
          partialResults: true,
          cancelOnError: true,
          listenFor: const Duration(seconds: 12),
          pauseFor: const Duration(seconds: 3),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _message = 'Could not listen: $error';
          _isListening = false;
        });
      }
      await _closeSession();
    }
  }

  void _handleResult(SpeechRecognitionResult result, String languageCode) {
    if (!mounted) return;
    setState(() {
      _transcript = result.recognizedWords;
      if (!result.finalResult) _message = 'Recognizing…';
    });
    if (!result.finalResult || _handledFinalResult) return;

    _handledFinalResult = true;
    setState(() => _message = 'Command received.');
    unawaited(_runRecognizedCommand(result.recognizedWords, languageCode));
  }

  Future<void> _runRecognizedCommand(
    String transcript,
    String languageCode,
  ) async {
    try {
      await widget.onRecognized(transcript, languageCode);
    } catch (error) {
      if (mounted) {
        setState(() => _message = 'Could not process that command: $error');
      }
    }
  }

  void _handleStatus(String status) {
    if (!mounted) return;
    setState(() {
      _isListening = status == 'listening';
      if (status == 'listening') {
        _message = 'Listening…';
      } else if (status == 'done') {
        _message = _handledFinalResult
            ? 'Command received.'
            : 'No command was recognized.';
      }
    });
    if (status == 'done') unawaited(_closeSession());
  }

  void _handleError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _message = 'Speech recognition error: ${error.errorMsg}';
    });
    unawaited(_closeSession());
  }

  Future<void> _cancelListening() async {
    try {
      await _speech.cancel();
    } catch (_) {
      // The session may already have timed out at the platform level.
    }
    if (mounted) setState(() => _isListening = false);
    await _closeSession();
  }

  Future<void> _closeSession() async {
    if (!_sessionOpen) return;
    _sessionOpen = false;
    final shouldRestorePlayback = !_handledFinalResult;
    if (mounted) setState(() => _isListening = false);
    if (shouldRestorePlayback) await widget.onListeningCancelled();
  }

  static String? _baseLanguage(String? value) {
    if (value == null) return null;
    final code = value.toLowerCase().replaceAll('_', '-').split('-').first;
    return const {'en', 'hi', 'mr'}.contains(code) ? code : null;
  }

  static String? _languageForLocale(String localeId) => _baseLanguage(localeId);

  static String _languageName(String code) => switch (code) {
    'en' => 'English',
    'hi' => 'Hindi',
    'mr' => 'Marathi',
    _ => code,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final languageAvailable = _selectedLocaleId != null;
    final processing = _sessionOpen && !_isListening;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.record_voice_over, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Voice commands',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening ? colors.error : colors.outline,
                  ),
                ),
                const SizedBox(width: 8),
                Text(_isListening ? 'Listening' : 'Mic off'),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedLocaleId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Voice-command language',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Choose a supported language'),
              items: _supportedLocales
                  .map(
                    (locale) => DropdownMenuItem(
                      value: locale.localeId,
                      child: Text(
                        '${locale.name} (${_languageName(_languageForLocale(locale.localeId)!)})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _isListening || _preparing
                  ? null
                  : (localeId) {
                      if (localeId != null) unawaited(_selectLocale(localeId));
                    },
            ),
            const SizedBox(height: 10),
            Text(_message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Semantics(
                label: 'Recognized speech',
                child: SelectableText(
                  _transcript.isEmpty
                      ? 'Recognized command will appear here.'
                      : _transcript,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            if (widget.feedback != null && widget.feedback!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.feedback!,
                key: const ValueKey('voice-command-feedback'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _preparing || processing ? null : _toggleListening,
                icon: Icon(_isListening ? Icons.stop : Icons.mic),
                label: Text(
                  _isListening
                      ? 'Stop listening'
                      : _preparing
                      ? 'Preparing microphone…'
                      : processing
                      ? 'Processing…'
                      : 'Listen',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
            ),
            if (_available && !languageAvailable && _supportedLocales.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Only English, Hindi, and Marathi commands are enabled.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
