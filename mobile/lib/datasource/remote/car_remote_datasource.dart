import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../api/http_client.dart';
import '../../config/env.dart';
import '../../models/car.dart';

class CarRemoteDataSource {
  CarRemoteDataSource(this._client);

  final HttpClient _client;

  Future<List<Car>> fetchCars() async {
    final response = await _client.get('/my-cars', json: false);
    if (response.statusCode >= 400) {
      throw Exception('Failed to load cars: ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final cars = json['cars'] as List<dynamic>;
    return cars.map((item) => _carFromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Car> createCar({required String name}) async {
    final response = await _client.post('/my-cars', {'name': name});
    if (response.statusCode >= 400) {
      throw Exception('Failed to create car: ${response.body}');
    }
    return _carFromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Car> updateCarName(String carId, String name) async {
    final response = await _client.patch('/my-cars/$carId', {'name': name});
    if (response.statusCode >= 400) {
      throw Exception('Failed to rename car: ${response.body}');
    }
    return _carFromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteCar(String carId) async {
    final response = await _client.delete('/my-cars/$carId');
    if (response.statusCode >= 400) {
      throw Exception('Failed to delete car: ${response.body}');
    }
  }

  Future<RenderResult> saveRender({
    required String carId,
    required String jobId,
    String? name,
    Uint8List? originalBytes,
    Uint8List? renderedBytes,
    String renderedExt = 'png',
    double? qualityScore,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${Env.apiBaseUrl}/my-cars/$carId/renders'),
    );
    request.headers.addAll(await _client.authHeaders(json: false));
    request.fields['job_id'] = jobId;
    if (name != null) request.fields['name'] = name;
    request.fields['rendered_ext'] = renderedExt;
    if (qualityScore != null) {
      request.fields['quality_score'] = qualityScore.toString();
    }
    if (originalBytes != null && originalBytes.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes(
        'original',
        originalBytes,
        filename: 'original.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    }
    if (renderedBytes != null && renderedBytes.isNotEmpty) {
      final ext = renderedExt.contains('png') ? 'png' : 'jpg';
      request.files.add(http.MultipartFile.fromBytes(
        'rendered',
        renderedBytes,
        filename: 'rendered.$ext',
        contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
      ));
    }

    final response = await _client.sendMultipart(request);
    if (response.statusCode >= 400) {
      throw Exception('Failed to save render: ${response.body}');
    }
    return _renderFromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<RenderResult> updateRenderName({
    required String carId,
    required String renderId,
    required String name,
  }) async {
    final response = await _client.patch(
      '/my-cars/$carId/renders/$renderId',
      {'name': name},
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to rename render: ${response.body}');
    }
    return _renderFromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteRender(String carId, String renderId) async {
    final response = await _client.delete('/my-cars/$carId/renders/$renderId');
    if (response.statusCode >= 400) {
      throw Exception('Failed to delete render: ${response.body}');
    }
  }

  Future<Uint8List?> downloadImage(String path) async {
    final response = await _client.get(path, json: false);
    if (response.statusCode >= 400) {
      return null;
    }
    return response.bodyBytes;
  }

  Car _carFromJson(Map<String, dynamic> json) {
    final rendersJson = json['renders'] as List<dynamic>? ?? [];
    return Car(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'My Car',
      createdAt: DateTime.parse(json['created_at'] as String),
      renders: rendersJson
          .map((item) => _renderFromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  RenderResult _renderFromJson(Map<String, dynamic> json) {
    return RenderResult(
      id: json['id'] as String,
      jobId: json['job_id'] as String? ?? '',
      name: json['name'] as String?,
      originalPath: json['original_url'] as String?,
      renderedPath: json['rendered_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      qualityScore: json['quality_score'] != null
          ? (json['quality_score'] as num).toDouble()
          : null,
    );
  }
}
