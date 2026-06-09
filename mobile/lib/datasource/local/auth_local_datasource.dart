import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/user.dart';

class AuthLocalDataSource {
  static const _refreshKey = 'refresh_token';
  static const _userKey = 'user_json';
  static const _sessionKey = 'session_id';
  static const _storageTimeout = Duration(seconds: 4);

  static const _storage = FlutterSecureStorage();

  Future<({String? refreshToken, String? sessionId, User? user})> loadSession() async {
    final results = await Future.wait<String?>([
      _storage.read(key: _refreshKey),
      _storage.read(key: _sessionKey),
      _storage.read(key: _userKey),
    ]).timeout(_storageTimeout);

    User? user;
    final userJson = results[2];
    if (userJson != null) {
      try {
        user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {
        user = null;
      }
    }

    return (refreshToken: results[0], sessionId: results[1], user: user);
  }

  Future<void> persist({
    required String refreshToken,
    String? sessionId,
    required User user,
  }) async {
    await _storage.write(key: _refreshKey, value: refreshToken);
    if (sessionId != null) {
      await _storage.write(key: _sessionKey, value: sessionId);
    }
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> saveUser(User user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> clear() async {
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _sessionKey);
  }
}
