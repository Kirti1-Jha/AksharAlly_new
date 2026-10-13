import 'package:cloud_firestore/cloud_firestore.dart';

import 'onboarding_storage.dart';

/// Account profile fields keyed by Firebase UID.
class UserProfileService {
  static const _collection = 'userProfiles';

  static DocumentReference<Map<String, dynamic>> _documentFor(String uid) {
    if (uid.trim().isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'A Firebase UID is required.');
    }
    return FirebaseFirestore.instance.collection(_collection).doc(uid);
  }

  static Future<Map<String, dynamic>> load(String uid) async {
    final snapshot = await _documentFor(uid).get();
    return snapshot.data() ?? <String, dynamic>{};
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
    await _documentFor(uid).set(profile, SetOptions(merge: true));
  }

  static Future<void> saveOnboarding(
    String uid,
    OnboardingProfile profile,
  ) async {
    await _documentFor(uid).set(
      {
        'fullName': profile.fullName.trim(),
        'preferredLanguage': profile.defaultReadingLanguage,
        'ageGroup': profile.ageGroup,
        'onboarding': profile.toJson(),
        'onboardingCompleted': profile.completed,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}

abstract interface class OnboardingAccountStore {
  Future<Map<String, dynamic>> load(String uid);
  Future<void> saveOnboarding(String uid, OnboardingProfile profile);
}

class FirestoreOnboardingAccountStore implements OnboardingAccountStore {
  const FirestoreOnboardingAccountStore();

  @override
  Future<Map<String, dynamic>> load(String uid) =>
      UserProfileService.load(uid);

  @override
  Future<void> saveOnboarding(String uid, OnboardingProfile profile) =>
      UserProfileService.saveOnboarding(uid, profile);
}
