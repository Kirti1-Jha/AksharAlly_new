import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';

import '../services/auth_flow.dart';
import '../services/onboarding_storage.dart';
import '../services/tts_service.dart';
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
    this.authFlow,
    this.ttsService,
  });

  final String? uid;
  final OnboardingStorage? storage;
  final OnboardingAccountStore? accountStore;
  final AuthFlow? authFlow;
  final TTSService? ttsService;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  late final OnboardingStorage _storage = widget.storage ?? OnboardingStorage();
  late final OnboardingAccountStore _accountStore =
      widget.accountStore ?? const FirestoreOnboardingAccountStore();
  late Future<_GateResult> _result;

  @override
  void initState() {
    super.initState();
    _result = _load();
  }

  void _retry() {
    final retry = _load();
    setState(() {
      _result = retry;
    });
  }

  Future<_GateResult> _load() async {
    final uid = widget.uid;
    if (uid == null || uid.isEmpty) return const _GateResult.login();
    final authenticatedUid =
        widget.authFlow?.currentUserId ??
        FirebaseAuth.instance.currentUser?.uid;
    if (authenticatedUid != uid) return const _GateResult.login();

    // The authenticated UID is checked above. Firestore is authoritative when
    // available; only UID-scoped saved data is used for recovery.
    late final Map<String, dynamic> account;
    try {
      account = await _accountStore.load(uid);
    } on FirebaseException catch (error, stackTrace) {
      _logProfileFailure('load', error, stackTrace);
      final cachedProfile = await _loadCachedProfile(uid);
      if (cachedProfile == null) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      await _storage.applyReadingPreferences(cachedProfile);
      return cachedProfile.completed
          ? _GateResult.home(cachedProfile)
          : _GateResult.onboarding(cachedProfile);
    }
    final accountStatus = account['onboardingCompleted'];
    if (accountStatus != null && accountStatus is! bool) {
      throw const FormatException(
        'The saved account onboarding status is invalid.',
      );
    }
    final remoteProfile = _profileFromAccount(account);

    if (accountStatus == true) {
      // The account-level completion flag is authoritative. Older account
      // documents may not have every nested onboarding field (including the
      // nested `completed` flag), so parse known values and default the rest.
      final profile = _completedProfileFromAccount(account, remoteProfile);
      await _storage.save(uid, profile);
      await _storage.applyReadingPreferences(profile);
      return _GateResult.home(profile);
    }

    final profile = await _loadCachedProfile(uid);

    // Migrate older same-device completions to the account record once. All
    // later decisions are made from the remote completion field.
    if (accountStatus == null &&
        (remoteProfile?.completed == true ||
            (remoteProfile == null && profile?.completed == true))) {
      final completed = remoteProfile ?? profile!;
      await _saveRemoteProfileIfAvailable(uid, completed);
      await _storage.applyReadingPreferences(completed);
      return _GateResult.home(completed);
    }

    final draft =
        remoteProfile?.copyWith(completed: false) ??
        (accountStatus == false
            ? profile?.copyWith(completed: false)
            : profile);
    final savedName = account['fullName'] is String
        ? account['fullName'] as String
        : '';
    final initial = draft ?? OnboardingProfile.initial(fullName: savedName);
    if (remoteProfile == null) {
      await _storage.save(uid, initial);
      await _saveRemoteProfileIfAvailable(uid, initial);
    }
    return _GateResult.onboarding(initial);
  }

  Future<OnboardingProfile?> _loadCachedProfile(String uid) async {
    try {
      return await _storage.load(uid);
    } on FormatException {
      await _storage.clear(uid);
      return null;
    } on TypeError {
      await _storage.clear(uid);
      return null;
    }
  }

  Future<void> _saveRemoteProfileIfAvailable(
    String uid,
    OnboardingProfile profile,
  ) async {
    try {
      await _accountStore.saveOnboarding(uid, profile);
    } on FirebaseException catch (error, stackTrace) {
      _logProfileFailure('save', error, stackTrace);
      // The authenticated user's local profile remains available. The next
      // successful profile load or onboarding save can sync it to Firestore.
    }
  }

  OnboardingProfile _completedProfileFromAccount(
    Map<String, dynamic> account,
    OnboardingProfile? remoteProfile,
  ) {
    final data = _profileDataFromAccount(account);
    final profile = remoteProfile ?? OnboardingProfile.fromJson(data);
    final accountName = account['fullName'];
    return profile.copyWith(
      fullName: profile.fullName.trim().isNotEmpty
          ? profile.fullName
          : accountName is String
          ? accountName
          : '',
      currentStep: 4,
      completed: true,
    );
  }

  OnboardingProfile? _profileFromAccount(Map<String, dynamic> account) {
    final data = account['onboarding'];
    if (data is! Map) return null;
    return OnboardingProfile.fromJson(_profileDataFromAccount(account));
  }

  Map<String, dynamic> _profileDataFromAccount(Map<String, dynamic> account) {
    final raw = account['onboarding'];
    final data = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    final accountName = account['fullName'];
    if ((data['fullName'] is! String ||
            (data['fullName'] as String).trim().isEmpty) &&
        accountName is String) {
      data['fullName'] = accountName;
    }

    const supportedLanguages = {'en', 'hi', 'mr'};
    final accountLanguage = account['preferredLanguage'];
    if (accountLanguage is String &&
        supportedLanguages.contains(accountLanguage)) {
      final savedLanguages = data['preferredLanguages'];
      final hasSupportedLanguage =
          savedLanguages is List &&
          savedLanguages.any(
            (language) =>
                language is String && supportedLanguages.contains(language),
          );
      if (!hasSupportedLanguage) {
        data['preferredLanguages'] = [accountLanguage];
      }
      if (!supportedLanguages.contains(data['defaultReadingLanguage'])) {
        data['defaultReadingLanguage'] = accountLanguage;
      }
    }

    final accountAgeGroup = account['ageGroup'];
    if ((data['ageGroup'] is! String || (data['ageGroup'] as String).isEmpty) &&
        accountAgeGroup is String) {
      data['ageGroup'] = accountAgeGroup;
    }
    return data;
  }

  String _profileFailureDetails(Object error) {
    if (error is FirebaseException) {
      final message = error.message;
      return '${error.plugin}/${error.code}'
          '${message == null || message.isEmpty ? '' : ': $message'}';
    }
    return '${error.runtimeType}: $error';
  }

  void _logProfileFailure(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!kDebugMode) return;
    debugPrint(
      'Reading profile $operation failed: ${_profileFailureDetails(error)}',
    );
    if (error is! FirebaseException) {
      debugPrintStack(stackTrace: stackTrace);
    }
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
                    if (kDebugMode && snapshot.error != null) ...[
                      const SizedBox(height: 8),
                      SelectableText(
                        _profileFailureDetails(snapshot.error!),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _retry, child: const Text('Retry')),
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
        if (result.showLogin) {
          return LoginScreen(
            authFlow: widget.authFlow,
            ttsService: widget.ttsService,
          );
        }
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
  const _GateResult.home(OnboardingProfile profile) : this._(profile: profile);
  const _GateResult.onboarding(OnboardingProfile profile)
    : this._(profile: profile);

  final OnboardingProfile? profile;
  final bool showLogin;
}
