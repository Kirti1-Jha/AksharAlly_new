import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Stores non-sensitive onboarding preferences locally for the signed-in UID.
///
/// Firebase Auth remains the source of identity and the full name is also
/// written to the Firebase user profile. This store only covers optional
/// preferences because the project does not currently use Firestore.
class UserProfileService {
  static String _key(String uid) => 'aksharally_profile_$uid';

  static Future<void> save({
    required String uid,
    required String fullName,
    required String preferredLanguage,
    String? ageGroup,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(uid),
      jsonEncode({
        'fullName': fullName.trim(),
        'preferredLanguage': preferredLanguage,
        if (ageGroup != null && ageGroup.isNotEmpty) 'ageGroup': ageGroup,
      }),
    );
  }

  static Future<Map<String, dynamic>> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(uid));
    if (raw == null) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}