import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/foundation.dart'
    show debugPrint, debugPrintStack, kDebugMode;
import 'package:flutter/material.dart';

import '../services/auth_flow.dart';
import '../services/auth_service.dart';
import '../services/tts_service.dart';
import '../theme/app_settings.dart';
import '../theme/app_theme.dart';
import '../theme/ui_accessibility.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authFlow, this.ttsService});

  final AuthFlow? authFlow;
  final TTSService? ttsService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  bool obscurePassword = true;
  bool _authenticating = false;
  bool _voiceAssistantEnabled = AppSettings.voiceAssistanceEnabled;
  int _narrationRequest = 0;
  String? _voiceNotice;
  Future<void> _voiceRestoreFuture = Future<void>.value();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  late final AuthFlow _authFlow;
  late final TTSService _tts;

  static const _gradientColors = [
    AppTheme.primaryBlue,
    AppTheme.primaryBlueLight,
  ];

  @override
  void initState() {
    super.initState();
    _authFlow = widget.authFlow ?? FirebaseAuthFlow();
    _tts = widget.ttsService ?? TTSService();
    if (_voiceAssistantEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_narrateText(_screenNarration));
      });
    }
  }

  String get _screenNarration => [
    isLogin
        ? 'Sign in with your email and password.'
        : 'Create Account. Enter your email and password to register.',
    'Email field.',
    'Password field.',
    isLogin ? 'Login button.' : 'Register button.',
    'Choose Login to sign in or Register to create an account.',
    'Continue with Google button.',
    'Continue with Apple button.',
  ].join(' ');

  void _setLoginMode(bool login) {
    if (isLogin == login || _authenticating) return;
    setState(() {
      isLogin = login;
      _voiceNotice = null;
    });
    if (_voiceAssistantEnabled) {
      unawaited(_narrateText(_screenNarration));
    } else {
      _narrationRequest++;
    }
  }

  void _toggleVoiceAssistant() {
    final enabled = !_voiceAssistantEnabled;
    setState(() {
      _voiceAssistantEnabled = enabled;
      _voiceNotice = null;
    });
    unawaited(AppSettings.saveVoiceAssistancePreference(enabled));
    if (enabled) {
      unawaited(_narrateText(_screenNarration));
    } else {
      _narrationRequest++;
      unawaited(_stopNarration());
    }
  }

  bool _isCurrentNarration(int request) =>
      mounted && _voiceAssistantEnabled && request == _narrationRequest;

  Future<void> _narrateText(String text) async {
    if (!_voiceAssistantEnabled || text.isEmpty) return;
    final request = ++_narrationRequest;
    try {
      await _voiceRestoreFuture;
      if (!_isCurrentNarration(request)) return;
      await _tts.init(defaultLocale: TTSService.preferredEnglishLocale);
      if (!_isCurrentNarration(request)) return;

      if (_tts.currentLocale == null) {
        await _tts.setLanguage(TTSService.preferredEnglishLocale);
        if (!_isCurrentNarration(request)) return;
      }
      if (_tts.currentLocale == null) {
        setState(() {
          _voiceNotice =
              _tts.localeNotice ??
              'Voice assistance is unavailable on this device.';
        });
        return;
      }

      await _tts.speak(
        text,
        onComplete: _restoreVoice,
        onError: (_) {
          _restoreVoice();
          if (!_isCurrentNarration(request)) return;
          setState(() {
            _voiceNotice =
                'Voice assistant could not read this screen. Turn it off and on to retry.';
          });
        },
      );
      if (_isCurrentNarration(request) && _tts.localeNotice != null) {
        setState(() => _voiceNotice = _tts.localeNotice);
      }
    } catch (_) {
      if (_isCurrentNarration(request)) {
        setState(() {
          _voiceNotice =
              'Voice assistant could not read this screen. '
              'Turn it off and on to retry.';
        });
      }
    }
  }

  void _restoreVoice() {
    final restore = _tts.resetVoiceToDefault();
    _voiceRestoreFuture = restore;
    unawaited(restore);
  }

  Future<void> _stopNarration() async {
    if (!_tts.isSpeaking && !_tts.isPaused) return;
    try {
      await _tts.stop();
    } catch (_) {
      // The platform may already have stopped the current utterance.
    }
    await _tts.resetVoiceToDefault();
  }

  Future<void> _stopAndRestoreTts() async {
    _narrationRequest++;
    await _voiceRestoreFuture;
    await _stopNarration();
  }

  @override
  void dispose() {
    _narrationRequest++;
    unawaited(_stopAndRestoreTts());
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String _withoutEnteredValues(String message) {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    var safeMessage = message;
    if (email.isNotEmpty) safeMessage = safeMessage.replaceAll(email, 'email');
    if (password.isNotEmpty) {
      safeMessage = safeMessage.replaceAll(password, 'password');
    }
    return safeMessage;
  }

  Future<void> handleAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (_authenticating) return;

    if (email.isEmpty || password.isEmpty) {
      const message = 'Please enter email & password';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(message)));
      unawaited(_narrateText(message));
      return;
    }

    await _authenticate(
      () => isLogin
          ? _authFlow.login(email, password)
          : _authFlow.register(email, password),
    );
  }

  Future<void> _authenticate(
    Future<AuthFlowResult?> Function() signIn,
  ) async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _voiceNotice = null;
    });
    try {
      final authResult = await signIn();
      if (authResult == null) return;
      await _stopAndRestoreTts();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacementNamed('/home', arguments: authResult);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        if (error is FirebaseAuthException) {
          debugPrint(
            'Firebase authentication failed: '
            '${error.code}${error.message == null ? '' : ': ${error.message}'}',
          );
        } else {
          debugPrint(
            'Authentication/navigation failed (${error.runtimeType}).',
          );
          debugPrintStack(stackTrace: stackTrace);
        }
      }
      final message = _withoutEnteredValues(AuthService.friendlyError(error));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      unawaited(_narrateText(message));
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
  }

  Widget _modeButton(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          key: ValueKey('login-mode-${label.toLowerCase()}'),
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          onTap: _authenticating ? null : onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? UIAccessibility.accentColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? UIAccessibility.onAccentColor
                    : UIAccessibility.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton({required String label, required bool apple}) {
    return OutlinedButton.icon(
      key: ValueKey(apple ? 'sign-in-apple' : 'sign-in-google'),
      onPressed: _authenticating
          ? null
          : () => unawaited(
              _authenticate(
                apple ? _authFlow.signInWithApple : _authFlow.signInWithGoogle,
              ),
            ),
      icon: apple
          ? const Icon(Icons.phone_iphone_outlined)
          : Text(
              'G',
              style: TextStyle(
                color: UIAccessibility.textColor,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: UIAccessibility.textColor,
        backgroundColor: UIAccessibility.surfaceColor,
        minimumSize: const Size(double.infinity, 52),
        side: BorderSide(
          color: UIAccessibility.textColor.withOpacity(0.18),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        textStyle: UIAccessibility.applyGlobalTextStyle(
          AppTheme.bodyStrongStyle,
        ).copyWith(color: UIAccessibility.textColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIAccessibility.backgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              20,
              constraints.maxHeight < 620 ? 8 : 20,
              20,
              24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Semantics(
                        button: true,
                        toggled: _voiceAssistantEnabled,
                        label: _voiceAssistantEnabled
                            ? 'Voice assistant on'
                            : 'Voice assistant off',
                        child: TextButton.icon(
                          key: const ValueKey('voice-assistant-toggle'),
                          onPressed: _toggleVoiceAssistant,
                          icon: Icon(
                            _voiceAssistantEnabled
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _voiceAssistantEnabled ? 'Voice on' : 'Voice off',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: UIAccessibility.textColor,
                            backgroundColor: UIAccessibility.surfaceColor,
                            minimumSize: const Size(44, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusFull,
                              ),
                            ),
                            textStyle: UIAccessibility.applyGlobalTextStyle(
                              AppTheme.labelStyle,
                            ).copyWith(color: UIAccessibility.textColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: _gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLG,
                          ),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'AksharAlly',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: UIAccessibility.textColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Read with confidence.',
                      textAlign: TextAlign.center,
                      style: UIAccessibility.applyGlobalTextStyle(
                        AppTheme.bodyStyle,
                      ).copyWith(
                        color: UIAccessibility.mutedTextColor,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Card(
                      color: UIAccessibility.surfaceColor,
                      elevation: 1,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                        side: BorderSide(
                          color: UIAccessibility.textColor.withOpacity(0.08),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: UIAccessibility.backgroundColor,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusLG,
                                ),
                              ),
                              child: Row(
                                children: [
                                  _modeButton(
                                    'Login',
                                    isLogin,
                                    () => _setLoginMode(true),
                                  ),
                                  _modeButton(
                                    'Register',
                                    !isLogin,
                                    () => _setLoginMode(false),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              isLogin ? 'Welcome Back!' : 'Create Account',
                              textAlign: TextAlign.center,
                              style: UIAccessibility.applyGlobalTextStyle(
                                AppTheme.headingStyle,
                              ).copyWith(
                                color: UIAccessibility.textColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isLogin
                                  ? 'Sign in to continue reading.'
                                  : 'Create your account to personalise your reading.',
                              textAlign: TextAlign.center,
                              style: UIAccessibility.applyGlobalTextStyle(
                                AppTheme.bodyStyle,
                              ).copyWith(
                                color: UIAccessibility.mutedTextColor,
                              ),
                            ),
                            if (_voiceNotice != null) ...[
                              const SizedBox(height: 8),
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  _voiceNotice!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            TextField(
                              key: const ValueKey('email-field'),
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              key: const ValueKey('password-field'),
                              controller: passwordController,
                              obscureText: obscurePassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) {
                                if (!_authenticating) unawaited(handleAuth());
                              },
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
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
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              key: const ValueKey('auth-submit'),
                              onPressed: _authenticating
                                  ? null
                                  : () => handleAuth(),
                              style: FilledButton.styleFrom(
                                backgroundColor: UIAccessibility.accentColor,
                                foregroundColor: UIAccessibility.onAccentColor,
                                minimumSize: const Size(
                                  double.infinity,
                                  AppTheme.buttonHeight,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusXL,
                                  ),
                                ),
                                textStyle:
                                    UIAccessibility.applyGlobalTextStyle(
                                      AppTheme.buttonTextStyle,
                                    ).copyWith(
                                      color: UIAccessibility.onAccentColor,
                                    ),
                              ),
                              child: _authenticating
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: UIAccessibility.onAccentColor,
                                      ),
                                    )
                                  : Text(isLogin ? 'Login' : 'Register'),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: UIAccessibility.textColor.withOpacity(
                                      0.15,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'Or continue with',
                                    style: UIAccessibility.applyGlobalTextStyle(
                                      AppTheme.captionStyle,
                                    ).copyWith(
                                      color: UIAccessibility.mutedTextColor,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: UIAccessibility.textColor.withOpacity(
                                      0.15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _socialButton(
                              label: 'Continue with Google',
                              apple: false,
                            ),
                            const SizedBox(height: 10),
                            _socialButton(
                              label: 'Continue with Apple',
                              apple: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
