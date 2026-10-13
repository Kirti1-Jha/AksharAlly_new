import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Device-local profile fields keyed by Firebase UID.
///
/// The project has no cloud profile provider or Firestore dependency. This
/// adapter intentionally uses the existing SharedPreferences dependency and
/// does not imply that profile fields sync between devices.
class UserProfileService {
  static const _keyPrefix = 'aksharally.user-profile.v1.';

  static String _keyFor(String uid) {
    if (uid.trim().isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'A Firebase UID is required.');
    }
    return '$_keyPrefix$uid';
  }

  static Future<Map<String, dynamic>> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(uid));
    if (raw == null) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // Treat malformed local data as an empty profile and recover on save.
    }
    return <String, dynamic>{};
  }

  static Future<void> save({
    required String uid,
    required String fullName,
    required String preferredLanguage,
    String? ageGroup,
  }) async {
    final existing = await load(uid);
    final profile = <String, dynamic>{
      ...existing,
      if (fullName.trim().isNotEmpty) 'fullName': fullName.trim(),
      if (preferredLanguage.trim().isNotEmpty)
        'preferredLanguage': preferredLanguage.trim(),
      if (ageGroup != null && ageGroup.trim().isNotEmpty)
        'ageGroup': ageGroup.trim(),
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(uid), jsonEncode(profile));
  }
}
