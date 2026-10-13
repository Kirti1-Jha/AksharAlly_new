import 'dart:async';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/tts_service.dart';

class LoginScreen extends StatefulWidget {
  static const welcomeMessage =
      'Welcome to AksharAlly, your personalised reading companion. '
      'Sign in to continue or create an account to get started.';

  const LoginScreen({super.key, this.ttsService});

  final TTSService? ttsService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  bool obscurePassword = true;
  bool _welcomeInProgress = false;
  bool _automaticWelcomeAttempted = false;
  String? _welcomeNotice;
  Future<void>? _welcomeAttempt;
  Future<void> _voiceRestoreFuture = Future<void>.value();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  late final TTSService _tts;

  @override
  void initState() {
    super.initState();
    _tts = widget.ttsService ?? TTSService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _requestWelcome();
    });
  }

  void _requestWelcome({bool replay = false}) {
    final attempt = _playWelcome(replay: replay);
    _welcomeAttempt = attempt;
    unawaited(attempt);
  }

  Future<void> _playWelcome({bool replay = false}) async {
    if (_welcomeInProgress ||
        (!replay && _automaticWelcomeAttempted) ||
        (!replay && (_tts.isSpeaking || _tts.isPaused))) {
      return;
    }
    if (!replay) _automaticWelcomeAttempted = true;
    _welcomeInProgress = true;
    if (mounted) {
      setState(() {
        _welcomeNotice = null;
      });
    }

    try {
      await _voiceRestoreFuture;
      if (!mounted) return;
      await _tts.init(defaultLocale: TTSService.preferredEnglishLocale);
      if (!mounted) return;

      // Retry locale selection when the device was temporarily unavailable.
      if (_tts.currentLocale == null) {
        await _tts.setLanguage(TTSService.preferredEnglishLocale);
      }
      if (!mounted) return;

      if (_tts.isSpeaking || _tts.isPaused) {
        if (!replay) return;
        await _tts.stop();
        if (!mounted) return;
      }

      if (_tts.currentLocale == null) {
        setState(() {
          _welcomeNotice =
              _tts.localeNotice ?? 'Welcome audio is unavailable on this device.';
        });
        return;
      }

      await _tts.speak(
        LoginScreen.welcomeMessage,
        onComplete: _scheduleVoiceRestore,
        onError: (_) {
          _scheduleVoiceRestore();
          if (!mounted) return;
          setState(() {
            _welcomeNotice =
                'Welcome audio could not be played. Tap replay to try again.';
          });
        },
      );
      if (!mounted) {
        await _stopTts();
        return;
      }
      if (_tts.localeNotice != null) {
        setState(() => _welcomeNotice = _tts.localeNotice);
      }
    } catch (_) {
      await _stopAndRestoreVoice();
      if (mounted) {
        setState(() {
          _welcomeNotice =
              'Welcome audio could not be played. Tap replay to try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _welcomeInProgress = false);
    }
  }

  void _scheduleVoiceRestore() {
    final restoration = _restoreVoice();
    _voiceRestoreFuture = restoration;
    unawaited(restoration);
  }

  Future<void> _restoreVoice() async {
    await _tts.resetVoiceToDefault();
  }

  Future<void> _stopAndRestoreVoice() async {
    try {
      await _tts.stop();
    } catch (_) {
      // The plugin may already have stopped while this screen is closing.
    }
    await _tts.resetVoiceToDefault();
  }

  Future<void> _stopAndRestoreTts() async {
    final attempt = _welcomeAttempt;
    if (attempt != null) await attempt;
    await _voiceRestoreFuture;
    await _stopAndRestoreVoice();
  }

  @override
  void dispose() {
    unawaited(_stopAndRestoreTts());
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  static const gradientColors = [
    Color(0xFF1565C0),
    Color(0xFF42A5F5),
  ];

  // HANDLE LOGIN / REGISTER
  Future<void> handleAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email & password")),
      );
      return;
    }

    try {
      final auth = AuthService();
      if (isLogin) {
        // LOGIN
        final user = await auth.login(email, password);

        if (user != null) {
          await _stopAndRestoreTts();
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // REGISTER
        final user = await auth.register(email, password);

        if (user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Registered successfully! Please login")),
          );
          setState(() {
            isLogin = true;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // ICON
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: gradientColors),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // LOGIN / REGISTER TOGGLE
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () => setState(() => isLogin = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: isLogin
                                    ? const LinearGradient(colors: gradientColors)
                                    : null,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  "Login",
                                  style: TextStyle(
                                    color: isLogin ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () => setState(() => isLogin = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: !isLogin
                                    ? const LinearGradient(colors: gradientColors)
                                    : null,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  "Register",
                                  style: TextStyle(
                                    color: !isLogin ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // TITLE
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        const LinearGradient(colors: gradientColors)
                            .createShader(bounds),
                    child: Text(
                      isLogin ? "Welcome Back!" : "Create Account",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextButton.icon(
                    onPressed: _welcomeInProgress
                        ? null
                        : () => _requestWelcome(replay: true),
                    icon: const Icon(Icons.volume_up_outlined),
                    label: const Text('Replay welcome message'),
                  ),

                  if (_welcomeNotice != null)
                    Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _welcomeNotice!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),

                  const SizedBox(height: 22),

                  // EMAIL FIELD
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: "Email",
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // PASSWORD FIELD
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      hintText: "Password",
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // LOGIN / REGISTER BUTTON
                  InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: handleAuth,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF66BB6A),
                            Color(0xFF43A047),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          isLogin ? "Login" : "Register",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Or continue with",
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  // GOOGLE BUTTON (placeholder)
                  _socialButton("Continue with Google"),

                  const SizedBox(height: 15),

                  // APPLE BUTTON (placeholder)
                  _socialButton("Continue with Apple"),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // SOCIAL BUTTON UI
  Widget _socialButton(String text) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$text coming soon")),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}