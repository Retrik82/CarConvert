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
