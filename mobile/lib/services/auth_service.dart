import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/auth_tokens.dart';
import '../models/user.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userKey = 'user_json';

  final _storage = const FlutterSecureStorage();
  String? _accessToken;
  String? _refreshToken;
  User? _user;

  User? get currentUser => _user;
  String? get accessToken => _accessToken;
  bool get isLoggedIn => _accessToken != null && _user != null;

  Future<void> loadStoredSession() async {
    _accessToken = await _storage.read(key: _accessKey);
    _refreshToken = await _storage.read(key: _refreshKey);
    final userJson = await _storage.read(key: _userKey);
    if (userJson != null) {
      _user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    }
  }

  Future<void> _persist(AuthTokens tokens) async {
    _accessToken = tokens.accessToken;
    _refreshToken = tokens.refreshToken;
    _user = tokens.user;
    await _storage.write(key: _accessKey, value: tokens.accessToken);
    await _storage.write(key: _refreshKey, value: tokens.refreshToken);
    await _storage.write(key: _userKey, value: jsonEncode({
      'id': tokens.user.id,
      'email': tokens.user.email,
      'display_name': tokens.user.displayName,
      'created_at': tokens.user.createdAt.toIso8601String(),
    }));
  }

  Future<AuthTokens> register(String email, String password, String name) async {
    final response = await http.post(
      Uri.parse('${Env.apiBaseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'display_name': name,
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception(_extractError(response.body));
    }
    final tokens = AuthTokens.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    await _persist(tokens);
    return tokens;
  }

  Future<AuthTokens> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${Env.apiBaseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode >= 400) {
      throw Exception(_extractError(response.body));
    }
    final tokens = AuthTokens.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    await _persist(tokens);
    return tokens;
  }

  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;
    final response = await http.post(
      Uri.parse('${Env.apiBaseUrl}/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': _refreshToken}),
    );
    if (response.statusCode >= 400) return false;
    final tokens = AuthTokens.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    await _persist(tokens);
    return true;
  }

  Future<void> logout() async {
    if (_refreshToken != null && _accessToken != null) {
      try {
        await http.post(
          Uri.parse('${Env.apiBaseUrl}/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_accessToken',
          },
          body: jsonEncode({'refresh_token': _refreshToken}),
        );
      } catch (_) {}
    }
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    await _storage.deleteAll();
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
