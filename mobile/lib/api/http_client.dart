import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';

typedef AuthHeadersBuilder = Future<Map<String, String>> Function({bool json});
typedef RefreshTokenCallback = Future<bool> Function();
typedef LogoutCallback = Future<void> Function();

class HttpClient {
  HttpClient({
    required AuthHeadersBuilder buildAuthHeaders,
    required RefreshTokenCallback refreshToken,
    required LogoutCallback onUnauthorizedLogout,
  })  : _buildAuthHeaders = buildAuthHeaders,
        _refreshToken = refreshToken,
        _onUnauthorizedLogout = onUnauthorizedLogout;

  final AuthHeadersBuilder _buildAuthHeaders;
  final RefreshTokenCallback _refreshToken;
  final LogoutCallback _onUnauthorizedLogout;

  static const apiTimeout = Duration(seconds: 45);

  Future<http.Response> authorized(Future<http.Response> Function() request) async {
    var response = await request();
    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        response = await request();
      }
      if (response.statusCode == 401) {
        await _onUnauthorizedLogout();
      }
    }
    return response;
  }

  Future<http.Response> get(String path, {bool json = false}) {
    return authorized(() async {
      return http
          .get(
            Uri.parse('${Env.apiBaseUrl}$path'),
            headers: await _buildAuthHeaders(json: json),
          )
          .timeout(apiTimeout);
    });
  }

  Future<http.Response> put(String path, Map<String, dynamic> body) {
    return authorized(() async {
      return http
          .put(
            Uri.parse('${Env.apiBaseUrl}$path'),
            headers: await _buildAuthHeaders(),
            body: jsonEncode(body),
          )
          .timeout(apiTimeout);
    });
  }

  Future<http.Response> post(String path, Map<String, dynamic> body, {bool useAuth = true}) async {
    Future<http.Response> send() {
      return http
          .post(
            Uri.parse('${Env.apiBaseUrl}$path'),
            headers: useAuth ? const {'Content-Type': 'application/json'} : const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(apiTimeout);
    }

    if (useAuth) {
      return authorized(send);
    }
    return send();
  }

  Future<http.Response> postPublic(String path, Map<String, dynamic> body) async {
    try {
      return await http
          .post(
            Uri.parse('${Env.apiBaseUrl}$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(apiTimeout);
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

  Future<http.Response> sendMultipart(http.MultipartRequest request) {
    return authorized(() async {
      final streamed = await request.send().timeout(const Duration(seconds: 90));
      return http.Response.fromStream(streamed);
    });
  }

  Future<Map<String, String>> authHeaders({bool json = true}) => _buildAuthHeaders(json: json);

  Future<void> wakeServer({int attempts = 3}) async {
    final uri = Uri.parse('${Env.apiBaseUrl}/health');
    for (var i = 0; i < attempts; i++) {
      try {
        final response = await http.get(uri).timeout(const Duration(seconds: 45));
        if (response.statusCode == 200) return;
      } catch (_) {}
      await Future<void>.delayed(Duration(seconds: 2 * (i + 1)));
    }
  }
}
