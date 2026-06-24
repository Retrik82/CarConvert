import 'dart:convert';

import '../../api/http_client.dart';
import '../../models/pricing_estimate.dart';

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

  Future<double> getCustomBackgroundPrice() async {
    final response = await _client.get('/settings/custom-background-price', json: false);
    if (response.statusCode >= 400) {
      throw Exception('Failed to load custom background price: ${response.body}');
    }
    return _parsePrice(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<double> setCustomBackgroundPrice(double priceUsd) async {
    final response = await _client.put('/admin/settings/custom-background-price', {'price_usd': priceUsd});
    if (response.statusCode >= 400) {
      throw Exception('Failed to update custom background price: ${response.body}');
    }
    return _parsePrice(jsonDecode(response.body) as Map<String, dynamic>, fallback: priceUsd);
  }

  Future<AdminPricingEstimate> getPricingEstimate() async {
    final response = await _client.get('/admin/settings/pricing-estimate', json: false);
    if (response.statusCode >= 400) {
      throw Exception('Failed to load pricing estimate: ${response.body}');
    }
    return AdminPricingEstimate.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  double _parsePrice(Map<String, dynamic> json, {double fallback = 0.10}) {
    final price = json['price_usd'];
    if (price is num) return price.toDouble();
    return double.tryParse(price.toString()) ?? fallback;
  }
}
