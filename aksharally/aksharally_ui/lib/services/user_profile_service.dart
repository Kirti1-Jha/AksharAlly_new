import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, debugPrintStack, kDebugMode;

import 'onboarding_storage.dart';

/// Account profile fields keyed by Firebase UID.
class UserProfileService {
  static const _collection = 'userProfiles';

  static String _authStatus(String uid) {
    try {
      final authenticatedUid = FirebaseAuth.instance.currentUser?.uid;
      return 'authenticated=${authenticatedUid != null} '
          'uidMatches=${authenticatedUid != null && authenticatedUid == uid}';
    } catch (error) {
      return 'authenticated=unknown uidMatches=unknown '
          'authStatusError=${error.runtimeType}';
    }
  }

  static Future<T> _traceFirestore<T>(
    String operation,
    String uid,
    Future<T> Function() run,
  ) async {
    final path = '$_collection/$uid';
    if (kDebugMode) {
      debugPrint(
        'FIRESTORE operation=$operation path=$path ${_authStatus(uid)}',
      );
    }
    try {
      final result = await run();
      if (kDebugMode) {
        debugPrint(
          'FIRESTORE operation=$operation path=$path '
          '${_authStatus(uid)} result=success',
        );
      }
      return result;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        if (error is FirebaseException) {
          debugPrint(
            'FIRESTORE operation=$operation path=$path '
            '${_authStatus(uid)} result=error plugin=${error.plugin} '
            'code=${error.code} message=${error.message}',
          );
        } else {
          debugPrint(
            'FIRESTORE operation=$operation path=$path '
            '${_authStatus(uid)} result=error type=${error.runtimeType}',
          );
          debugPrintStack(stackTrace: stackTrace);
        }
      }
      rethrow;
    }
  }

  static DocumentReference<Map<String, dynamic>> _documentFor(String uid) {
    if (uid.trim().isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'A Firebase UID is required.');
    }
    return FirebaseFirestore.instance.collection(_collection).doc(uid);
  }

  static Future<Map<String, dynamic>> load(String uid) async {
    return _traceFirestore('GET', uid, () async {
      final snapshot = await _documentFor(uid).get();
      if (kDebugMode) {
        debugPrint(
          'FIRESTORE operation=GET path=$_collection/$uid '
          'documentExists=${snapshot.exists}',
        );
      }
      return snapshot.data() ?? <String, dynamic>{};
    });
  }

  static Future<void> save({
    required String uid,
    required String fullName,
    required String preferredLanguage,
    String? ageGroup,
  }) async {
    final profile = <String, Object?>{
      if (fullName.trim().isNotEmpty) 'fullName': fullName.trim(),
      if (preferredLanguage.trim().isNotEmpty)
        'preferredLanguage': preferredLanguage.trim(),
      if (ageGroup != null && ageGroup.trim().isNotEmpty)
        'ageGroup': ageGroup.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _traceFirestore('SET merge=true', uid, () async {
      await _documentFor(uid).set(profile, SetOptions(merge: true));
    });
  }

  static Future<void> saveOnboarding(
    String uid,
    OnboardingProfile profile,
  ) async {
    await _traceFirestore('SET onboarding merge=true', uid, () async {
      await _documentFor(uid).set({
        'fullName': profile.fullName.trim(),
        'preferredLanguage': profile.defaultReadingLanguage,
        'ageGroup': profile.ageGroup,
        'onboarding': profile.toJson(),
        'onboardingCompleted': profile.completed,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}

abstract interface class OnboardingAccountStore {
  Future<Map<String, dynamic>> load(String uid);
  Future<void> saveOnboarding(String uid, OnboardingProfile profile);
}

class FirestoreOnboardingAccountStore implements OnboardingAccountStore {
  const FirestoreOnboardingAccountStore();

  @override
  Future<Map<String, dynamic>> load(String uid) => UserProfileService.load(uid);

  @override
  Future<void> saveOnboarding(String uid, OnboardingProfile profile) =>
      UserProfileService.saveOnboarding(uid, profile);
}
