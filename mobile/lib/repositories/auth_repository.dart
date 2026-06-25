import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

import '../api/http_client.dart';
import '../datasource/local/auth_local_datasource.dart';
import '../datasource/local/device_local_datasource.dart';
import '../datasource/remote/auth_remote_datasource.dart';
import '../models/auth_tokens.dart';
import '../models/user.dart';

typedef AuthStateListener = void Function(bool loggedIn);

class AuthRepository {
  AuthRepository._() {
    _httpClient = HttpClient(
      buildAuthHeaders: _buildAuthHeaders,
      refreshToken: refreshAccessToken,
      onUnauthorizedLogout: logout,
    );
    _remote = AuthRemoteDataSource(_httpClient);
  }

  static final AuthRepository instance = AuthRepository._();

  final _local = AuthLocalDataSource();
  final _device = DeviceLocalDataSource();
  final _listeners = <AuthStateListener>{};

  late final HttpClient _httpClient;
  late final AuthRemoteDataSource _remote;

  String? _accessToken;
  String? _refreshToken;
  String? _sessionId;
  User? _user;
  Future<void>? _refreshInFlight;

  HttpClient get httpClient => _httpClient;

  User? get currentUser => _user;
  String? get accessToken => _accessToken;
  String? get sessionId => _sessionId;
  bool get isLoggedIn => _refreshToken != null && _user != null;

  void addListener(AuthStateListener listener) => _listeners.add(listener);

  void removeListener(AuthStateListener listener) => _listeners.remove(listener);

  void _notifyAuthState() {
    final loggedIn = isLoggedIn;
    for (final listener in _listeners) {
      listener(loggedIn);
    }
  }

  Future<void> loadStoredSession() async {
    _accessToken = null;
    _refreshToken = null;
    _sessionId = null;
    _user = null;

    final stored = await _local.loadSession();
    _refreshToken = stored.refreshToken;
    _sessionId = stored.sessionId;
    _user = stored.user;
  }

  Future<bool> validateSession() async {
    if (_refreshToken == null) return false;
    if (_accessToken == null) {
      try {
        final ok = await refreshAccessToken();
        if (!ok) return _user != null;
      } catch (_) {
        return _user != null;
      }
    }
    try {
      final user = await _remote.fetchCurrentUser();
      _user = user;
      await _local.saveUser(user);
      return true;
    } catch (_) {
      return _accessToken != null && _user != null;
    }
  }

  Future<User> refreshCurrentUser() async {
    if (_accessToken == null && !await refreshAccessToken()) {
      throw Exception('Not logged in');
    }
    final user = await _remote.fetchCurrentUser();
    _user = user;
    await _local.saveUser(user);
    return user;
  }

  /// Ensures a valid access token before long-running API calls.
  Future<void> ensureSessionReady({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_refreshToken == null) {
      throw Exception('Not logged in');
    }
    if (_accessToken != null) return;

    final refreshed = await refreshAccessToken().timeout(
      timeout,
      onTimeout: () => false,
    );
    if (!refreshed || _accessToken == null) {
      throw Exception('Not logged in');
    }
  }

  Future<Map<String, String>> _buildAuthHeaders({bool json = true}) async {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    if (_sessionId != null) headers['X-Session-Id'] = _sessionId!;
    headers['X-Device-Id'] = await _device.getDeviceId();
    headers['X-Device-Name'] = _deviceName();
    return headers;
  }

  Future<void> _persist(AuthTokens tokens) async {
    _accessToken = tokens.accessToken;
    _refreshToken = tokens.refreshToken;
    _sessionId = tokens.sessionId;
    _user = tokens.user;
    await _local.persist(
      refreshToken: tokens.refreshToken,
      sessionId: tokens.sessionId,
      user: tokens.user,
    );
  }

  Future<Map<String, String>> _deviceBodyFields() async {
    return {
      'device_id': await _device.getDeviceId(),
      'device_name': _deviceName(),
    };
  }

  String _deviceName() {
    if (kIsWeb) return 'Web';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    return 'Mobile';
  }

  Future<AuthTokens> register(String email, String password, String name) async {
    final tokens = await _remote.register({
      'email': email,
      'password': password,
      'display_name': name,
      ...(await _deviceBodyFields()),
    });
    await _persist(tokens);
    _notifyAuthState();
    return tokens;
  }

  Future<AuthTokens> login(String email, String password) async {
    final tokens = await _remote.login({
      'email': email,
      'password': password,
      ...(await _deviceBodyFields()),
    });
    await _persist(tokens);
    _notifyAuthState();
    return tokens;
  }

  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;
    if (_refreshInFlight != null) {
      await _refreshInFlight;
      return _accessToken != null;
    }
    final completer = Completer<void>();
    _refreshInFlight = completer.future;
    try {
      final tokens = await _remote.refresh(_refreshToken!);
      await _persist(tokens);
      return true;
    } catch (_) {
      return false;
    } finally {
      completer.complete();
      _refreshInFlight = null;
    }
  }

  Future<void> logout() async {
    if (_refreshToken != null) {
      await _remote.logout(_accessToken, _refreshToken!);
    }
    _accessToken = null;
    _refreshToken = null;
    _sessionId = null;
    _user = null;
    await _local.clear();
    _notifyAuthState();
  }

  Future<void> forgotPassword(String email) async {
    await _remote.forgotPassword(email.trim());
  }

  Future<void> updateLocalProfile({String? displayName, String? avatarPath}) async {
    if (_user == null) return;
    if (displayName != null) {
      _user = _user!.copyWith(displayName: displayName);
    }
    await _local.saveUser(_user!);
  }

  Future<void> logoutAllDevices({bool keepCurrent = true}) async {
    if (_accessToken == null && !await refreshAccessToken()) return;
    await _remote.logoutAllDevices(keepCurrent: keepCurrent);
  }
}
