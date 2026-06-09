import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PrefsLocalDataSource {
  String _profileKey(String userId) => 'profile_override_$userId';

  Future<Map<String, String>?> getProfileOverride(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey(userId));
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return json.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<void> saveProfileOverride(
    String userId, {
    String? displayName,
    String? avatarPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getProfileOverride(userId) ?? {};
    if (displayName != null) existing['display_name'] = displayName;
    if (avatarPath != null) existing['avatar_path'] = avatarPath;
    await prefs.setString(_profileKey(userId), jsonEncode(existing));
  }
}
