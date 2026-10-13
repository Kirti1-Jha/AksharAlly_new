import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthIdentity {
  const AuthIdentity({
    required this.uid,
    this.email,
    this.displayName,
  });

  final String uid;
  final String? email;
  final String? displayName;
}

abstract interface class AuthGateway {
  Future<AuthIdentity?> register(String email, String password);
  Future<AuthIdentity?> login(String email, String password);
  Future<AuthIdentity?> signInWithGoogle();
}

class AuthService implements AuthGateway {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static Future<void>? _googleSignInInitialization;

  AuthIdentity? _identity(User? user) => user == null
      ? null
      : AuthIdentity(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
        );

  // REGISTER
  @override
  Future<User?> register(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = _identity(result.user);
    return user == null
        ? null
        : _FirebaseUserView._(user, result.user!);
  }

  // LOGIN
  @override
  Future<User?> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = _identity(result.user);
    return user == null
        ? null
        : _FirebaseUserView._(user, result.user!);
  }

  @override
  Future<AuthIdentity?> signInWithGoogle() async {
    UserCredential result;
    if (kIsWeb) {
      result = await _auth.signInWithPopup(GoogleAuthProvider());
    } else {
      final googleSignIn = GoogleSignIn.instance;
      try {
        _googleSignInInitialization ??= googleSignIn.initialize();
        await _googleSignInInitialization;
      } catch (_) {
        _googleSignInInitialization = null;
        rethrow;
      }
      if (!googleSignIn.supportsAuthenticate()) {
        throw UnsupportedError(
          'Google sign-in is not available on this platform.',
        );
      }
      final googleUser = await googleSignIn.authenticate();
      final credential = GoogleAuthProvider.credential(
        idToken: googleUser.authentication.idToken,
      );
      result = await _auth.signInWithCredential(credential);
    }
    return _identity(result.user);
  }

  // GET TOKEN
  Future<String?> getToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
    if (!kIsWeb && _googleSignInInitialization != null) {
      await GoogleSignIn.instance.signOut();
    }
  }
}

class _FirebaseUserView extends User implements AuthIdentity {
  _FirebaseUserView._(AuthIdentity identity, this._user)
    : uid = identity.uid,
      email = identity.email,
      displayName = identity.displayName;

  final User _user;

  @override
  final String uid;

  @override
  final String? email;

  @override
  final String? displayName;

  @override
  noSuchMethod(Invocation invocation) => _user.noSuchMethod(invocation);
}