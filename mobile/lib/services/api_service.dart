import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

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
    return headers;
  }

  Future<http.Response> _authorized(Future<http.Response> Function() request) async {
    var response = await request();
    if (response.statusCode == 401) {
      final refreshed = await AuthService.instance.refreshAccessToken();
      if (refreshed) {
        response = await request();
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

  Future<ProcessJob> processPhoto(Uint8List bytes, String filename, {String? sessionId}) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${Env.apiBaseUrl}/photo/process'),
    );
    final token = AuthService.instance.accessToken;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: filename));
    if (sessionId != null) request.fields['session_id'] = sessionId;

    final streamed = await request.send().timeout(const Duration(seconds: 180));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 401) {
      final refreshed = await AuthService.instance.refreshAccessToken();
      if (refreshed) return processPhoto(bytes, filename, sessionId: sessionId);
    }
    if (response.statusCode >= 400) {
      throw Exception('Process failed: ${response.body}');
    }
    return ProcessJob.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
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
}
