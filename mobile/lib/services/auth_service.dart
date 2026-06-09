import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/auth_tokens.dart';
import '../models/user.dart';
import 'device_service.dart';

typedef AuthStateListener = void Function(bool loggedIn);

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _listeners = <AuthStateListener>{};

  static const _refreshKey = 'refresh_token';
  static const _userKey = 'user_json';
  static const _sessionKey = 'session_id';

  final _storage = const FlutterSecureStorage();

  /// Access token lives in memory only (never persisted).
  String? _accessToken;
  String? _refreshToken;
  String? _sessionId;
  User? _user;

  Future<void>? _refreshInFlight;

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

  /// Loads tokens and profile from secure storage only (no network).
  Future<void> loadStoredSession() async {
    _accessToken = null;
    _refreshToken = await _storage.read(key: _refreshKey);
    _sessionId = await _storage.read(key: _sessionKey);
    final userJson = await _storage.read(key: _userKey);
    if (userJson != null) {
      _user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    }
  }

  Future<bool> validateSession() async {
    if (_refreshToken == null) return false;
    if (_accessToken == null) {
      final ok = await refreshAccessToken();
      if (!ok) {
        await logout();
        return false;
      }
    }
    try {
      final response = await http
          .get(
            Uri.parse('${Env.apiBaseUrl}/auth/me'),
            headers: await _authHeaders(),
          )
          .timeout(_apiTimeout);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _user = User.fromJson(json);
        await _storage.write(key: _userKey, value: jsonEncode(_user!.toJson()));
        return true;
      }
      if (response.statusCode == 401) {
        if (await refreshAccessToken()) return validateSession();
        await logout();
        return false;
      }
    } catch (_) {
      // Offline: allow entry only when access token is already in memory.
      return _accessToken != null && _user != null;
    }
    return false;
  }

  Future<User> refreshCurrentUser() async {
    if (_accessToken == null && !await refreshAccessToken()) {
      throw Exception('Not logged in');
    }
    final response = await http
        .get(
          Uri.parse('${Env.apiBaseUrl}/auth/me'),
          headers: await _authHeaders(),
        )
        .timeout(_apiTimeout);
    if (response.statusCode >= 400) {
      throw Exception(_extractError(response.body));
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    _user = User.fromJson(json);
    await _storage.write(key: _userKey, value: jsonEncode(_user!.toJson()));
    return _user!;
  }

  Future<Map<String, String>> _authHeaders({bool json = true}) async {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    if (_sessionId != null) headers['X-Session-Id'] = _sessionId!;
    final deviceId = await DeviceService.instance.getDeviceId();
    headers['X-Device-Id'] = deviceId;
    headers['X-Device-Name'] = _deviceName();
    return headers;
  }

  Future<void> _persist(AuthTokens tokens) async {
    _accessToken = tokens.accessToken;
    _refreshToken = tokens.refreshToken;
    _sessionId = tokens.sessionId;
    _user = tokens.user;
    await _storage.write(key: _refreshKey, value: tokens.refreshToken);
    if (tokens.sessionId != null) {
      await _storage.write(key: _sessionKey, value: tokens.sessionId);
    }
    await _storage.write(key: _userKey, value: jsonEncode(tokens.user.toJson()));
  }

  static const _apiTimeout = Duration(seconds: 45);

  Future<Map<String, String>> _deviceBodyFields() async {
    return {
      'device_id': await DeviceService.instance.getDeviceId(),
      'device_name': _deviceName(),
    };
  }

  String _deviceName() {
    if (kIsWeb) return 'Web';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    return 'Mobile';
  }

  Future<http.Response> _postJson(String path, Map<String, dynamic> body) async {
    try {
      return await http
          .post(
            Uri.parse('${Env.apiBaseUrl}$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_apiTimeout);
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('connection abort') ||
          msg.contains('Connection refused') ||
          msg.contains('Failed host lookup') ||
          msg.contains('TimeoutException')) {
        throw Exception(
          'Сервер не отвечает. Откройте ${Env.apiBaseUrl}/health в браузере.',
        );
      }
      rethrow;
    }
  }

  Future<AuthTokens> register(String email, String password, String name) async {
    final body = {
      'email': email,
      'password': password,
      'display_name': name,
      ...(await _deviceBodyFields()),
    };
    final response = await _postJson('/auth/register', body);
    if (response.statusCode >= 400) {
      throw Exception(_extractError(response.body));
    }
    final tokens = AuthTokens.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    await _persist(tokens);
    _notifyAuthState();
    return tokens;
  }

  Future<AuthTokens> login(String email, String password) async {
    final body = {
      'email': email,
      'password': password,
      ...(await _deviceBodyFields()),
    };
    final response = await _postJson('/auth/login', body);
    if (response.statusCode >= 400) {
      throw Exception(_extractError(response.body));
    }
    final tokens = AuthTokens.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    await _persist(tokens);
    _notifyAuthState();
    return tokens;
  }

  /// Single-flight refresh: concurrent 401s share one refresh request.
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;
    if (_refreshInFlight != null) {
      await _refreshInFlight;
      return _accessToken != null;
    }
    final completer = Completer<void>();
    _refreshInFlight = completer.future;
    try {
      final response = await _postJson('/auth/refresh', {
        'refresh_token': _refreshToken!,
      });
      if (response.statusCode >= 400) return false;
      final tokens = AuthTokens.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      await _persist(tokens);
      return true;
    } finally {
      completer.complete();
      _refreshInFlight = null;
    }
  }

  Future<void> logout() async {
    if (_refreshToken != null) {
      try {
        await http.post(
          Uri.parse('${Env.apiBaseUrl}/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
          },
          body: jsonEncode({'refresh_token': _refreshToken}),
        );
      } catch (_) {}
    }
    _accessToken = null;
    _refreshToken = null;
    _sessionId = null;
    _user = null;
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _sessionKey);
    _notifyAuthState();
  }

  Future<void> forgotPassword(String email) async {
    final response = await _postJson('/auth/forgot-password', {'email': email.trim()});
    if (response.statusCode >= 400) {
      throw Exception(_extractError(response.body));
    }
  }

  Future<void> updateLocalProfile({String? displayName, String? avatarPath}) async {
    if (_user == null) return;
    if (displayName != null) {
      _user = _user!.copyWith(displayName: displayName);
    }
    await _storage.write(key: _userKey, value: jsonEncode(_user!.toJson()));
  }

  Future<void> logoutAllDevices({bool keepCurrent = true}) async {
    if (_accessToken == null && !await refreshAccessToken()) return;
    await http.post(
      Uri.parse('${Env.apiBaseUrl}/auth/logout-all'),
      headers: await _authHeaders(),
      body: jsonEncode({'keep_current_session': keepCurrent}),
    );
  }

  String _extractError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['detail']?.toString() ?? json['error']?.toString() ?? 'Request failed';
    } catch (_) {
      return body;
    }
  }
}
