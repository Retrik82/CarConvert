import 'dart:convert';
import 'dart:typed_data';

import '../../api/http_client.dart';
import '../../config/env.dart';
import '../../models/background.dart';

class BackgroundRemoteDataSource {
  BackgroundRemoteDataSource(this._client);

  final HttpClient _client;

  Future<BackgroundCatalog> fetchCatalog() async {
    final response = await _client.get('/backgrounds', json: false);
    if (response.statusCode >= 400) {
      throw Exception('Failed to load backgrounds: ${response.body}');
    }
    return BackgroundCatalog.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<BackgroundPreset> createCustomBackground({
    required String name,
    required String prompt,
  }) async {
    final response = await _client.post(
      '/backgrounds/custom',
      {
        'name': name,
        'prompt': prompt,
      },
      timeout: HttpClient.backgroundGenerationTimeout,
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to create background: ${response.body}');
    }
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw Exception('Failed to create background: unexpected response format');
    }

    final nested = json['background'];
    if (nested is Map<String, dynamic>) {
      return BackgroundPreset.fromJson(nested);
    }

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      final background = data['background'];
      if (background is Map<String, dynamic>) {
        return BackgroundPreset.fromJson(background);
      }
    }

    // Backward-compatibility: some deployments may return the preset directly.
    if (json['id'] is String && json['name'] is String) {
      return BackgroundPreset.fromJson(json);
    }

    throw Exception('Failed to create background: missing background payload');
  }

  Future<Uint8List> fetchImageBytes(String previewPath) async {
    final uri = previewPath.startsWith('http')
        ? Uri.parse(previewPath)
        : Uri.parse('${Env.apiBaseUrl}$previewPath');

    final response = await _client.getUri(uri, json: false);
    if (response.statusCode >= 400) {
      throw Exception('Failed to load background image');
    }
    return response.bodyBytes;
  }
}
