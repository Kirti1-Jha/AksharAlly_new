import 'package:flutter/material.dart';

import '../services/tts_service.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.ttsService});

  final TTSService? ttsService;

  static const String welcomeMessage =
      'Welcome to AksharAlly, your personalised reading companion. '
      'Read with confidence. Select Let’s Begin to get started.';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final TTSService _ttsService = widget.ttsService ?? TTSService();
  bool _welcomeStarted = false;
  bool _isDisposed = false;
  int _playbackRequest = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playWelcome();
    });
  }

  Future<void> _playWelcome() async {
    if (_welcomeStarted || _isDisposed) return;
    _welcomeStarted = true;
    final request = ++_playbackRequest;

    try {
      await _speakWelcome(request);
    } catch (error) {
      debugPrint('Splash welcome speech unavailable: $error');
    }
  }

  Future<void> _replayWelcome() async {
    if (_isDisposed) return;
    final request = ++_playbackRequest;

    try {
      await _ttsService.stop();
      await _speakWelcome(request);
    } catch (error) {
      debugPrint('Could not replay splash welcome: $error');
    }
  }

  Future<void> _speakWelcome(int request) async {
    await _ttsService.init(defaultLocale: TTSService.preferredEnglishLocale);
    if (_isDisposed || request != _playbackRequest) return;

    if (_ttsService.currentLocale == null) {
      await _ttsService.setLanguage(TTSService.preferredEnglishLocale);
      if (_isDisposed || request != _playbackRequest) return;
    }

    await _ttsService.speak(SplashScreen.welcomeMessage);
  }

  void _openLogin() {
    _playbackRequest++;
    _ttsService.stop();
    Navigator.pushNamed(context, '/login');
  }

  @override
  void dispose() {
    _isDisposed = true;
    _playbackRequest++;
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppTheme.spaceLG,
          AppTheme.spaceLG,
          AppTheme.spaceLG,
          AppTheme.spaceXL,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 680;
            final verticalPadding = isCompact
                ? AppTheme.spaceMD
                : AppTheme.spaceLG;
            final iconWidth = (constraints.maxWidth * 0.46)
                .clamp(128.0, 176.0)
                .toDouble();
            final minimumContentHeight =
                (constraints.maxHeight - verticalPadding * 2)
                    .clamp(0.0, double.infinity)
                    .toDouble();

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: verticalPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 420,
                    minHeight: minimumContentHeight,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Semantics(
                        image: true,
                        label: 'AksharAlly logo',
                        child: Image.asset(
                          'assets/images/aksharally_logo.webp',
                          width: iconWidth,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: isCompact ? 14 : 20),
                      Text(
                        'AksharAlly',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSM),
                      Text(
                        'Read with confidence.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.72,
                          ),
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: isCompact ? 28 : 40),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _openLogin,
                            child: const Text("Let's Begin"),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSM),
                      Semantics(
                        button: true,
                        label: 'Repeat welcome message',
                        child: IconButton(
                          tooltip: 'Repeat welcome message',
                          onPressed: _replayWelcome,
                          icon: const Icon(Icons.volume_up_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
