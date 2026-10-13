import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_flow.dart';
import '../services/onboarding_storage.dart';
import '../services/user_profile_service.dart';
import '../services/tts_service.dart';
import '../theme/app_settings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.authFlow,
    this.accountStore,
    this.ttsService,
  });

  static const welcomeMessage =
      'Welcome to AksharAlly, your personalised reading companion.';

  final AuthFlow? authFlow;
  final OnboardingAccountStore? accountStore;
  final TTSService? ttsService;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AuthFlow _auth = widget.authFlow ?? FirebaseAuthFlow();
  late final OnboardingAccountStore _accountStore =
      widget.accountStore ?? const FirestoreOnboardingAccountStore();
  late final OnboardingStorage _storage = OnboardingStorage();
  late final TTSService _tts = widget.ttsService ?? TTSService();
  final Completer<void> _cancelPlayback = Completer<void>();
  Completer<void>? _activePlayback;
  Future<void> _voiceRestoreFuture = Future<void>.value();
  String? _voiceNotice;

  @override
  void initState() {
    super.initState();
    unawaited(_prepareSplash());
  }

  Future<void> _prepareSplash() async {
    final uid = _auth.currentUserId;
    if (uid != null) {
      await _loadVoicePreference(uid);
    }

    if (mounted && AppSettings.voiceAssistanceEnabled) {
      await _playWelcome();
    }

    if (mounted && uid != null) {
      Navigator.of(context).pushReplacementNamed('/home', arguments: uid);
    }
  }

  Future<void> _loadVoicePreference(String uid) async {
    try {
      final account = await _accountStore.load(uid);
      final data = account['onboarding'];
      if (data is Map) {
        final profile = OnboardingProfile.fromJson(
          Map<String, dynamic>.from(data),
        );
        await _storage.applyReadingPreferences(profile);
        await _storage.save(uid, profile);
        return;
      }
    } catch (_) {
      // The gate below shows the account-load error; local settings may still
      // provide the voice preference for this splash screen.
    }

    try {
      final local = await _storage.load(uid);
      if (local != null) await _storage.applyReadingPreferences(local);
    } catch (_) {
      // A missing or damaged local cache must not keep an authenticated user
      // from reaching the retry state in the onboarding gate.
    }
  }

  Future<void> _playWelcome() async {
    try {
      await _tts.init(defaultLocale: TTSService.preferredEnglishLocale);
      if (!mounted || !AppSettings.voiceAssistanceEnabled) return;
      if (_tts.currentLocale == null) {
        await _tts.setLanguage(TTSService.preferredEnglishLocale);
      }
      if (!mounted || _tts.currentLocale == null) {
        if (mounted) {
          setState(() {
            _voiceNotice =
                _tts.localeNotice ?? 'Welcome audio is unavailable on this device.';
          });
        }
        return;
      }

      final playback = Completer<void>();
      _activePlayback = playback;
      await _tts.speak(
        SplashScreen.welcomeMessage,
        onComplete: () {
          _restoreVoice();
          if (!playback.isCompleted) playback.complete();
        },
        onError: (_) {
          _restoreVoice();
          if (!playback.isCompleted) playback.complete();
          if (mounted) {
            setState(() {
              _voiceNotice = 'Welcome audio could not be played.';
            });
          }
        },
      );
      await Future.any<void>([
        playback.future,
        _cancelPlayback.future,
      ]).timeout(
        const Duration(seconds: 18),
        onTimeout: () async {
          await _stopTts();
        },
      );
      await _voiceRestoreFuture;
      if (mounted && _tts.localeNotice != null) {
        setState(() => _voiceNotice = _tts.localeNotice);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _voiceNotice = 'Welcome audio could not be played.';
        });
      }
      await _restoreVoice();
    } finally {
      _activePlayback = null;
    }
  }

  void _restoreVoice() {
    final restore = _tts.resetVoiceToDefault();
    _voiceRestoreFuture = restore;
    unawaited(restore);
  }

  Future<void> _stopTts() async {
    if (!_tts.isSpeaking && !_tts.isPaused) return;
    try {
      await _tts.stop();
    } catch (_) {
      // Ignore stop errors while the screen is closing.
    }
    await _voiceRestoreFuture;
  }

  Future<void> _openLogin() async {
    await _stopTts();
    final playback = _activePlayback;
    if (playback != null && !playback.isCompleted) playback.complete();
    if (mounted) Navigator.pushNamed(context, '/login');
  }

  @override
  void dispose() {
    if (!_cancelPlayback.isCompleted) _cancelPlayback.complete();
    final playback = _activePlayback;
    if (playback != null && !playback.isCompleted) playback.complete();
    unawaited(_stopTts());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1565C0),
              Color(0xFF42A5F5),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Text(
                'AksharAlly',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Assistive Reading for Dyslexia',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              if (_voiceNotice != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _voiceNotice!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1565C0),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _openLogin,
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
