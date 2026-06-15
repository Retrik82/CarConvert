import 'dart:typed_data';

import 'package:flutter/services.dart';

class LocalAssetLoader {
  LocalAssetLoader._();

  static final Map<String, Uint8List> _cache = {};

  static Future<Uint8List> loadBytes(String assetPath) async {
    final cached = _cache[assetPath];
    if (cached != null) return cached;

    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    _cache[assetPath] = bytes;
    return bytes;
  }

  static void clearCache() => _cache.clear();
}
