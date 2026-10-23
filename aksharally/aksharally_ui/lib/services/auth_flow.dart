import 'package:firebase_auth/firebase_auth.dart' show UserCredential;

import 'auth_service.dart';

/// Authentication surface used by the sign-in UI and routing tests.
class AuthFlowResult {
  const AuthFlowResult({required this.uid, required this.isNewUser});

  final String uid;
  final bool isNewUser;
}

abstract interface class AuthFlow {
  String? get currentUserId;

  Future<AuthFlowResult?> register(String email, String password);
  Future<AuthFlowResult?> login(String email, String password);
  Future<AuthFlowResult?> signInWithGoogle();
  Future<AuthFlowResult?> signInWithApple();
}

class FirebaseAuthFlow implements AuthFlow {
  FirebaseAuthFlow({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  @override
  String? get currentUserId => _authService.currentUser?.uid;

  @override
  Future<AuthFlowResult?> register(String email, String password) async =>
      _result(await _authService.register(email, password), assumeNewUser: true);

  @override
  Future<AuthFlowResult?> login(String email, String password) async =>
      _result(await _authService.login(email, password));

  @override
  Future<AuthFlowResult?> signInWithGoogle() async =>
      _result(await _authService.signInWithGoogle());

  @override
  Future<AuthFlowResult?> signInWithApple() async =>
      _result(await _authService.signInWithApple());

  AuthFlowResult? _result(
    UserCredential? credential, {
    bool assumeNewUser = false,
  }) {
    final user = credential?.user;
    if (user == null) return null;
    return AuthFlowResult(
      uid: user.uid,
      isNewUser:
          credential?.additionalUserInfo?.isNewUser ?? assumeNewUser,
    );
  }
}
