import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../api/http_client.dart';
import '../../config/env.dart';
import '../../models/history_item.dart';
import '../../models/process_job.dart';

class PhotoRemoteDataSource {
  PhotoRemoteDataSource(this._client);

  final HttpClient _client;

  Future<String> startSession() async {
    final response = await _client.authorized(() async {
      return http.post(
        Uri.parse('${Env.apiBaseUrl}/session/start'),
        headers: await _client.authHeaders(),
      );
    });
    if (response.statusCode >= 400) {
      throw Exception('Failed to start session: ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['session_id'] as String;
  }

  Future<ProcessJob> processPhoto(
    Uint8List bytes,
    String filename, {
    String? sessionId,
    String? backgroundPresetId,
    String? backgroundPresetSlug,
    String? userBackgroundId,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      if (attempt > 0) await _client.wakeServer();
      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${Env.apiBaseUrl}/photo/process'),
        );
        request.headers.addAll(await _client.authHeaders(json: false));
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: filename,
          contentType: MediaType('image', 'jpeg'),
        ));
        if (sessionId != null) request.fields['session_id'] = sessionId;
        if (backgroundPresetId != null) {
          request.fields['background_preset_id'] = backgroundPresetId;
        }
        if (backgroundPresetSlug != null) {
          request.fields['background_preset_slug'] = backgroundPresetSlug;
        }
        if (userBackgroundId != null) {
          request.fields['user_background_id'] = userBackgroundId;
        }

        final response = await _client.sendMultipart(request);
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
    final response = await _client.get('/photo/result/$jobId', json: false);
    if (response.statusCode >= 400) {
      throw Exception('Result fetch failed: ${response.body}');
    }
    return PhotoResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<HistoryItem>> getHistory() async {
    final response = await _client.get('/photos/history', json: false);
    if (response.statusCode >= 400) {
      throw Exception('History fetch failed: ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items = json['items'] as List<dynamic>;
    return items.map((e) => HistoryItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
