import 'package:flutter/material.dart';

import '../services/onboarding_storage.dart';
import '../services/user_profile_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

/// Keeps incomplete profiles in onboarding without changing authentication.
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({
    super.key,
    required this.uid,
    this.storage,
  });

  final String? uid;
  final OnboardingStorage? storage;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  late final OnboardingStorage _storage =
      widget.storage ?? OnboardingStorage();
  late final Future<_GateResult> _result = _load();

  Future<_GateResult> _load() async {
    final uid = widget.uid;
    if (uid == null || uid.isEmpty) return const _GateResult.login();

    OnboardingProfile? profile;
    try {
      profile = await _storage.load(uid);
    } on FormatException {
      await _storage.clear(uid);
    } on TypeError {
      await _storage.clear(uid);
    }

    if (profile?.completed == true) {
      await _storage.applyReadingPreferences(profile!);
      final savedProfile = await UserProfileService.load(uid);
      return _GateResult.home(
        profile.copyWith(
          fullName: profile.fullName.isNotEmpty
              ? profile.fullName
              : (savedProfile['fullName'] as String? ?? ''),
        ),
      );
    }
    final existing = await UserProfileService.load(uid);
    final initial = profile ?? OnboardingProfile.initial(
      fullName: existing['fullName'] as String? ?? '',
    );
    return _GateResult.onboarding(initial);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_GateResult>(
      future: _result,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Your reading profile could not be loaded. '
                      'Please try again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => OnboardingGate(
                            uid: widget.uid,
                            storage: _storage,
                          ),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final result = snapshot.data!;
        if (result.showLogin) return const LoginScreen();
        if (result.profile == null) return const HomeScreen();
        if (result.profile!.completed) return const HomeScreen();
        return OnboardingScreen(
          uid: widget.uid!,
          initialProfile: result.profile!,
          storage: _storage,
        );
      },
    );
  }
}

class _GateResult {
  const _GateResult._({this.profile, this.showLogin = false});

  const _GateResult.login() : this._(showLogin: true);
  const _GateResult.home(OnboardingProfile profile)
      : this._(profile: profile);
  const _GateResult.onboarding(OnboardingProfile profile)
      : this._(profile: profile);

  final OnboardingProfile? profile;
  final bool showLogin;
}
