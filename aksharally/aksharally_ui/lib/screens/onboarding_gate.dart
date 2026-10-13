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
    this.accountStore,
  });

  final String? uid;
  final OnboardingStorage? storage;
  final OnboardingAccountStore? accountStore;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  late final OnboardingStorage _storage =
      widget.storage ?? OnboardingStorage();
  late final OnboardingAccountStore _accountStore =
      widget.accountStore ?? const FirestoreOnboardingAccountStore();
  late final Future<_GateResult> _result = _load();

  Future<_GateResult> _load() async {
    final uid = widget.uid;
    if (uid == null || uid.isEmpty) return const _GateResult.login();

    // Firestore is authoritative for completion. SharedPreferences remains a
    // local draft/cache and is never used to bypass this account check.
    final account = await _accountStore.load(uid);
    final accountStatus = account['onboardingCompleted'];
    if (accountStatus != null && accountStatus is! bool) {
      throw const FormatException(
        'The saved account onboarding status is invalid.',
      );
    }
    final remoteProfile = _profileFromAccount(account);

    if (accountStatus == true) {
      final profile = remoteProfile;
      if (profile == null || !profile.completed) {
        throw const FormatException(
          'The saved account onboarding profile is incomplete.',
        );
      }
      await _storage.save(uid, profile);
      await _storage.applyReadingPreferences(profile);
      return _GateResult.home(profile);
    }

    OnboardingProfile? profile;
    try {
      profile = await _storage.load(uid);
    } on FormatException {
      await _storage.clear(uid);
    } on TypeError {
      await _storage.clear(uid);
    }

    // Migrate older same-device completions to the account record once. All
    // later decisions are made from the remote completion field.
    if (accountStatus == null &&
        (remoteProfile?.completed == true ||
            (remoteProfile == null && profile?.completed == true))) {
      final completed = remoteProfile ?? profile!;
      await _accountStore.saveOnboarding(uid, completed);
      await _storage.applyReadingPreferences(completed);
      return _GateResult.home(completed);
    }

    final draft = remoteProfile?.copyWith(completed: false) ??
        (accountStatus == false
            ? profile?.copyWith(completed: false)
            : profile);
    final savedName = account['fullName'] is String
        ? account['fullName'] as String
        : '';
    final initial = draft ?? OnboardingProfile.initial(
      fullName: savedName,
    );
    return _GateResult.onboarding(initial);
  }

  OnboardingProfile? _profileFromAccount(Map<String, dynamic> account) {
    final data = account['onboarding'];
    if (data is! Map) return null;
    return OnboardingProfile.fromJson(Map<String, dynamic>.from(data));
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
                            accountStore: _accountStore,
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
          accountStore: _accountStore,
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
