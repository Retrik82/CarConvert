import 'dart:typed_data';

import '../core/assets/bundled_assets.dart';
import '../core/assets/local_asset_loader.dart';
import '../datasource/remote/background_remote_datasource.dart';
import '../models/background.dart';
import 'auth_repository.dart';

class BackgroundRepository {
  BackgroundRepository._() {
    _remote = BackgroundRemoteDataSource(AuthRepository.instance.httpClient);
  }

  static final BackgroundRepository instance = BackgroundRepository._();

  late final BackgroundRemoteDataSource _remote;

  SelectedBackground? _selected;
  final Map<String, Uint8List> _imageCache = {};

  SelectedBackground? get selected => _selected;

  void select(BackgroundPreset preset, BackgroundVariant variant) {
    _selected = SelectedBackground(preset: preset, variant: variant);
  }

  void clearSelection() {
    _selected = null;
  }

  Future<BackgroundCatalog> fetchCatalog() => _remote.fetchCatalog();

  Future<BackgroundPreset> createCustomBackground({
    required String name,
    required String prompt,
  }) =>
      _remote.createCustomBackground(name: name, prompt: prompt);

  Future<Uint8List> fetchImageBytes(
    String previewPath, {
    String? presetSlug,
    String? angle,
  }) async {
    final cacheKey = presetSlug != null && angle != null
        ? 'bundled:$presetSlug/$angle'
        : previewPath;

    final cached = _imageCache[cacheKey];
    if (cached != null) return cached;

    if (presetSlug != null && angle != null) {
      final bundledPath = BundledAssets.presetBackgroundAssetPath(presetSlug, angle);
      if (bundledPath != null) {
        final bytes = await LocalAssetLoader.loadBytes(bundledPath);
        _imageCache[cacheKey] = bytes;
        return bytes;
      }
    }

    final bytes = await _remote.fetchImageBytes(previewPath);
    final data = Uint8List.fromList(bytes);
    _imageCache[cacheKey] = data;
    return data;
  }

  void clearImageCache() {
    _imageCache.clear();
    LocalAssetLoader.clearCache();
  }
}
