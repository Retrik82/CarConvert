import 'dart:typed_data';

import '../../api/http_client.dart';

class CarAssetRemoteDataSource {
  CarAssetRemoteDataSource(this._client);

  final HttpClient _client;

  Future<Uint8List> fetchImageBytes(String imagePath) async {
    final response = await _client.getPublic(imagePath);
    if (response.statusCode >= 400) {
      throw Exception('Failed to load car image');
    }
    return response.bodyBytes;
  }
}
