import 'package:flutter/material.dart';

import '../services/tts_service.dart';
import '../theme/app_settings.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.ttsService});

  final TTSService? ttsService;

  static const String welcomeMessage =
      'Welcome to Akshar Al-eye, your personalised reading companion. '
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

  Future<void> _selectInterfaceLanguage(String language) async {
    try {
      await AppSettings.saveInterfaceLanguagePreference(language);
      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('Could not save interface language: $error');
    }
  }

  Widget _languageSelector(ThemeData theme) {
    final isHindi = AppSettings.interfaceLanguage == 'hi';
    return Semantics(
      label: isHindi ? 'भाषा चुनें' : 'Choose language',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _languageOption(theme, 'en', 'EN', 'English'),
              _languageOption(theme, 'hi', 'हि', 'हिंदी'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageOption(
    ThemeData theme,
    String language,
    String label,
    String semanticLabel,
  ) {
    final selected = AppSettings.interfaceLanguage == language;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _selectInterfaceLanguage(language),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
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
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _languageSelector(theme),
            ),
            Expanded(
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
                              AppSettings.interfaceLanguage == 'hi'
                                  ? 'आत्मविश्वास के साथ पढ़ें।'
                                  : 'Read with confidence.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.72),
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
                                  child: Text(
                                    AppSettings.interfaceLanguage == 'hi'
                                        ? 'शुरू करें'
                                        : "Let's Begin",
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceSM),
                            Semantics(
                              button: true,
                              label: AppSettings.interfaceLanguage == 'hi'
                                  ? 'स्वागत संदेश दोहराएँ'
                                  : 'Repeat welcome message',
                              child: IconButton(
                                tooltip:
                                    AppSettings.interfaceLanguage == 'hi'
                                        ? 'स्वागत संदेश दोहराएँ'
                                        : 'Repeat welcome message',
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
          ],
        ),
      ),
    );
  }
}
