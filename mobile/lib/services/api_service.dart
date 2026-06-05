import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/env.dart';
import '../models/history_item.dart';
import '../models/process_job.dart';
import 'auth_service.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = AuthService.instance.accessToken;
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final sessionId = AuthService.instance.sessionId;
    if (sessionId != null) headers['X-Session-Id'] = sessionId;
    return headers;
  }

  Future<http.Response> _authorized(Future<http.Response> Function() request) async {
    var response = await request();
    if (response.statusCode == 401) {
      final refreshed = await AuthService.instance.refreshAccessToken();
      if (refreshed) {
        response = await request();
      }
      if (response.statusCode == 401) {
        await AuthService.instance.logout();
      }
    }
    return response;
  }

  Future<String> startSession() async {
    final response = await _authorized(() async {
      return http.post(
        Uri.parse('${Env.apiBaseUrl}/session/start'),
        headers: await _headers(),
      );
    });
    if (response.statusCode >= 400) {
      throw Exception('Failed to start session: ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['session_id'] as String;
  }

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

  Future<ProcessJob> processPhoto(Uint8List bytes, String filename, {String? sessionId}) async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      if (attempt > 0) await wakeServer();
      try {
        final response = await _authorized(() async {
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('${Env.apiBaseUrl}/photo/process'),
          );
          final headers = await _headers(json: false);
          request.headers.addAll(headers);

          request.files.add(http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: filename,
            contentType: MediaType('image', 'jpeg'),
          ));
          if (sessionId != null) request.fields['session_id'] = sessionId;

          final streamed = await request.send().timeout(const Duration(seconds: 90));
          return http.Response.fromStream(streamed);
        });
        if (response.statusCode >= 400) {
          throw Exception('Process failed: ${response.body}');
        }
        return ProcessJob.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('Не удалось отправить фото на сервер: $lastError');
  }

  Future<PhotoResult> getResult(String jobId) async {
    final response = await _authorized(() async {
      return http.get(
        Uri.parse('${Env.apiBaseUrl}/photo/result/$jobId'),
        headers: await _headers(json: false),
      );
    });
    if (response.statusCode >= 400) {
      throw Exception('Result fetch failed: ${response.body}');
    }
    return PhotoResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<HistoryItem>> getHistory() async {
    final response = await _authorized(() async {
      return http.get(
        Uri.parse('${Env.apiBaseUrl}/photos/history'),
        headers: await _headers(json: false),
      );
    });
    if (response.statusCode >= 400) {
      throw Exception('History fetch failed: ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items = json['items'] as List<dynamic>;
    return items.map((e) => HistoryItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<double> getGenerationPrice() async {
    final response = await _authorized(() async {
      return http.get(
        Uri.parse('${Env.apiBaseUrl}/settings/generation-price'),
        headers: await _headers(json: false),
      );
    });
    if (response.statusCode >= 400) {
      throw Exception('Failed to load price: ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final price = json['price_usd'];
    if (price is num) return price.toDouble();
    return double.tryParse(price.toString()) ?? 0.10;
  }

  Future<double> setGenerationPrice(double priceUsd) async {
    final response = await _authorized(() async {
      return http.put(
        Uri.parse('${Env.apiBaseUrl}/admin/settings/price'),
        headers: await _headers(),
        body: jsonEncode({'price_usd': priceUsd}),
      );
    });
    if (response.statusCode >= 400) {
      throw Exception('Failed to update price: ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final price = json['price_usd'];
    if (price is num) return price.toDouble();
    return double.tryParse(price.toString()) ?? priceUsd;
  }
}
