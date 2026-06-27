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

  Future<http.Response> get(String path, {bool json = false, Duration? timeout}) {
    final requestTimeout = timeout ?? apiTimeout;
    return authorized(() async {
      return http
          .get(
            Uri.parse('${Env.apiBaseUrl}$path'),
            headers: await _buildAuthHeaders(json: json),
          )
          .timeout(requestTimeout);
    });
  }

  Future<http.Response> getPublic(String path) {
    final uri = path.startsWith('http')
        ? Uri.parse(path)
        : Uri.parse('${Env.apiBaseUrl}$path');
    return http.get(uri).timeout(apiTimeout);
  }

  Future<http.Response> getUri(Uri uri, {bool json = false}) {
    return authorized(() async {
      return http
          .get(
            uri,
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

  Future<http.Response> patch(String path, Map<String, dynamic> body) {
    return authorized(() async {
      return http
          .patch(
            Uri.parse('${Env.apiBaseUrl}$path'),
            headers: await _buildAuthHeaders(),
            body: jsonEncode(body),
          )
          .timeout(apiTimeout);
    });
  }

  Future<http.Response> delete(String path) {
    return authorized(() async {
      return http
          .delete(
            Uri.parse('${Env.apiBaseUrl}$path'),
            headers: await _buildAuthHeaders(json: false),
          )
          .timeout(apiTimeout);
    });
  }

  Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    bool useAuth = true,
    Duration? timeout,
  }) async {
    final requestTimeout = timeout ?? apiTimeout;

    Future<http.Response> send() async {
      final headers = useAuth
          ? await _buildAuthHeaders()
          : const {'Content-Type': 'application/json'};
      return http
          .post(
            Uri.parse('${Env.apiBaseUrl}$path'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(requestTimeout);
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

  /// Pings `/health` to wake cold-hosted APIs. Throws when [required] and all attempts fail.
  Future<void> wakeServer({
    int attempts = 3,
    Duration requestTimeout = const Duration(seconds: 45),
    bool required = false,
  }) async {
    final uri = Uri.parse('${Env.apiBaseUrl}/health');
    Object? lastError;
    for (var i = 0; i < attempts; i++) {
      try {
        final response = await http.get(uri).timeout(requestTimeout);
        if (response.statusCode == 200) return;
        lastError = Exception('Health check returned ${response.statusCode}');
      } catch (e) {
        lastError = e;
      }
      if (i < attempts - 1) {
        await Future<void>.delayed(Duration(seconds: 1 + i));
      }
    }
    if (required) {
      throw Exception(
        'Сервер не отвечает. Откройте ${Env.apiBaseUrl}/health в браузере.',
      );
    }
    if (lastError != null) {
      // Best-effort warm-up — caller may still try the main request.
      return;
    }
  }
}
