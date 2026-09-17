import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../theme/app_settings.dart';
import 'user_profile_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const _appleServiceId =
      String.fromEnvironment('APPLE_SERVICE_ID');
  static const _appleRedirectUri =
      String.fromEnvironment('APPLE_REDIRECT_URI');

  // REGISTER
  Future<User?> register(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  // GOOGLE SIGN-IN
  Future<User?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  // APPLE SIGN-IN
  Future<User?> signInWithApple() async {
    try {
      final needsWebAuthentication =
          kIsWeb ||
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);
      if (needsWebAuthentication &&
          (_appleServiceId.isEmpty || _appleRedirectUri.isEmpty)) {
        throw StateError('Apple web authentication needs APPLE_SERVICE_ID '
            'and APPLE_REDIRECT_URI build settings.');
      }
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: needsWebAuthentication
            ? WebAuthenticationOptions(
                clientId: _appleServiceId,
                redirectUri: Uri.parse(_appleRedirectUri),
              )
            : null,
      );
      final credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final result = await _auth.signInWithCredential(credential);
      final appleName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
      if (result.user != null &&
          appleName.isNotEmpty &&
          (result.user!.displayName == null ||
              result.user!.displayName!.trim().isEmpty)) {
        await result.user!.updateDisplayName(appleName);
      }
      return result.user;
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
  }

  /// Saves the Firebase display name and optional onboarding preferences.
  /// Passwords are never included in this profile data.
  Future<void> saveUserProfile(
    User user, {
    String? fullName,
    String preferredLanguage = 'en',
    String? ageGroup,
  }) async {
    final existing = await UserProfileService.load(user.uid);
    final existingName = existing['fullName'] is String
        ? existing['fullName'] as String
        : '';
    final existingLanguage = existing['preferredLanguage'] is String
        ? existing['preferredLanguage'] as String
        : 'en';
    final existingAgeGroup =
        existing['ageGroup'] is String ? existing['ageGroup'] as String : null;
    final name =
        (fullName ?? user.displayName ?? existingName).trim();
    final language = preferredLanguage == 'en' && existingLanguage != 'en'
        ? existingLanguage
        : preferredLanguage;
    final selectedAgeGroup = ageGroup ?? existingAgeGroup;

    if (name.isNotEmpty && user.displayName != name) {
      await user.updateDisplayName(name);
    }
    await UserProfileService.save(
      uid: user.uid,
      fullName: name,
      preferredLanguage: language,
      ageGroup: selectedAgeGroup,
    );
    AppSettings.language = language;
  }

  Future<void> restoreUserPreferences(User user) async {
    final profile = await UserProfileService.load(user.uid);
    final language = profile['preferredLanguage'];
    if (language is String && language.isNotEmpty) {
      AppSettings.language = language;
    }
  }

  static String friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'That email is already registered. Try logging in instead.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Choose a stronger password with at least 6 characters.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'The email or password is incorrect.';
        case 'user-not-found':
          return 'No account was found for that email.';
        case 'network-request-failed':
          return 'Network error. Check your connection and try again.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with a different sign-in method.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled in Firebase yet.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        default:
          return 'Authentication failed. Please try again.';
      }
    }
    if (error is SignInWithAppleAuthorizationException) {
      return 'Apple Sign-In is not configured for this device yet.';
    }
    if (error is StateError &&
        error.message.toString().contains('APPLE_SERVICE_ID')) {
      return 'Apple Sign-In on Android needs its Apple service configuration.';
    }
    return 'Something went wrong. Please try again.';
  }

  // LOGIN
  Future<User?> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  // GET TOKEN
  Future<String?> getToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}