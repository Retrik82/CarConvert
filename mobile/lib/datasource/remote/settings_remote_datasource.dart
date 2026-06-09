import 'dart:convert';

import '../../api/http_client.dart';

class SettingsRemoteDataSource {
  SettingsRemoteDataSource(this._client);

  final HttpClient _client;

  Future<double> getGenerationPrice() async {
    final response = await _client.get('/settings/generation-price', json: false);
    if (response.statusCode >= 400) {
      throw Exception('Failed to load price: ${response.body}');
    }
    return _parsePrice(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<double> setGenerationPrice(double priceUsd) async {
    final response = await _client.put('/admin/settings/price', {'price_usd': priceUsd});
    if (response.statusCode >= 400) {
      throw Exception('Failed to update price: ${response.body}');
    }
    return _parsePrice(jsonDecode(response.body) as Map<String, dynamic>, fallback: priceUsd);
  }

  double _parsePrice(Map<String, dynamic> json, {double fallback = 0.10}) {
    final price = json['price_usd'];
    if (price is num) return price.toDouble();
    return double.tryParse(price.toString()) ?? fallback;
  }
}
