import 'auth_service.dart';

/// Authentication surface used by the sign-in UI and routing tests.
abstract interface class AuthFlow {
  String? get currentUserId;

  Future<String?> register(String email, String password);
  Future<String?> login(String email, String password);
  Future<String?> signInWithGoogle();
  Future<String?> signInWithApple();
}

class FirebaseAuthFlow implements AuthFlow {
  FirebaseAuthFlow({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  @override
  String? get currentUserId => _authService.currentUser?.uid;

  @override
  Future<String?> register(String email, String password) async =>
      (await _authService.register(email, password))?.uid;

  @override
  Future<String?> login(String email, String password) async =>
      (await _authService.login(email, password))?.uid;

  @override
  Future<String?> signInWithGoogle() async =>
      (await _authService.signInWithGoogle())?.uid;

  @override
  Future<String?> signInWithApple() async =>
      (await _authService.signInWithApple())?.uid;
}
