import '../models/auth_tokens.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';

export '../repositories/auth_repository.dart' show AuthStateListener;

/// @deprecated Use [AuthRepository] instead.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _repo = AuthRepository.instance;

  User? get currentUser => _repo.currentUser;
  String? get accessToken => _repo.accessToken;
  String? get sessionId => _repo.sessionId;
  bool get isLoggedIn => _repo.isLoggedIn;

  void addListener(AuthStateListener listener) => _repo.addListener(listener);
  void removeListener(AuthStateListener listener) => _repo.removeListener(listener);

  Future<void> loadStoredSession() => _repo.loadStoredSession();
  Future<bool> validateSession() => _repo.validateSession();
  Future<User> refreshCurrentUser() => _repo.refreshCurrentUser();
  Future<AuthTokens> register(String email, String password, String name) =>
      _repo.register(email, password, name);
  Future<AuthTokens> login(String email, String password) => _repo.login(email, password);
  Future<bool> refreshAccessToken() => _repo.refreshAccessToken();
  Future<void> logout() => _repo.logout();
  Future<void> forgotPassword(String email) => _repo.forgotPassword(email);
  Future<void> updateLocalProfile({String? displayName, String? avatarPath}) =>
      _repo.updateLocalProfile(displayName: displayName, avatarPath: avatarPath);
  Future<void> logoutAllDevices({bool keepCurrent = true}) =>
      _repo.logoutAllDevices(keepCurrent: keepCurrent);
}
