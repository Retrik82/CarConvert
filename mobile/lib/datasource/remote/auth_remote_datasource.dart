import 'dart:convert';

import '../../api/http_client.dart';
import '../../models/auth_tokens.dart';
import '../../models/user.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final HttpClient _client;

  Future<AuthTokens> register(Map<String, dynamic> body) async {
    final response = await _client.postPublic('/auth/register', body);
    if (response.statusCode >= 400) {
      throw Exception(_extractError(response.body));
    }
    return AuthTokens.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<AuthTokens> login(Map<String, dynamic> body) async {
    final response = await _client.postPublic('/auth/login', body);
    if (response.statusCode >= 400) {
      throw Exception(_extractError(response.body));
    }
    return AuthTokens.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final response = await _client.postPublic('/auth/refresh', {'refresh_token': refreshToken});
    if (response.statusCode >= 400) {
      throw Exception(_extractError(response.body));
    }
    return AuthTokens.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> logout(String? accessToken, String refreshToken) async {
    try {
      await _client.postPublic('/auth/logout', {'refresh_token': refreshToken});
    } catch (_) {}
  }

  Future<void> forgotPassword(String email) async {
    final response = await _client.postPublic('/auth/forgot-password', {'email': email});
    if (response.statusCode >= 400) {
      throw Exception(_extractError(response.body));
    }
  }

  Future<void> logoutAllDevices({required bool keepCurrent}) async {
    await _client.post('/auth/logout-all', {'keep_current_session': keepCurrent});
  }

  Future<User> fetchCurrentUser() async {
    final response = await _client.get('/auth/me');
    if (response.statusCode >= 400) {
      throw Exception(_extractError(response.body));
    }
    return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
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
