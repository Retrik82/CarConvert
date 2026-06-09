import '../repositories/profile_repository.dart';

/// @deprecated Use [ProfileRepository] instead.
class PrefsService {
  static final _repo = ProfileRepository.instance;

  static Future<Map<String, String>?> getProfileOverride(String userId) =>
      _repo.getProfileOverride(userId);

  static Future<void> saveProfileOverride(
    String userId, {
    String? displayName,
    String? avatarPath,
  }) =>
      _repo.saveProfileOverride(userId, displayName: displayName, avatarPath: avatarPath);
}
