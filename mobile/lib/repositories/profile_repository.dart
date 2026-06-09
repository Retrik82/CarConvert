import '../datasource/local/prefs_local_datasource.dart';

class ProfileRepository {
  ProfileRepository._();

  static final ProfileRepository instance = ProfileRepository._();

  final _local = PrefsLocalDataSource();

  Future<Map<String, String>?> getProfileOverride(String userId) =>
      _local.getProfileOverride(userId);

  Future<void> saveProfileOverride(
    String userId, {
    String? displayName,
    String? avatarPath,
  }) =>
      _local.saveProfileOverride(userId, displayName: displayName, avatarPath: avatarPath);
}
