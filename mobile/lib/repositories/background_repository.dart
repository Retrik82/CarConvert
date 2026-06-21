import 'dart:typed_data';

import '../core/assets/bundled_assets.dart';
import '../core/assets/bundled_background_catalog.dart';
import '../core/assets/local_asset_loader.dart';
import '../core/preferences/app_preferences.dart';
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

  Future<void> select(BackgroundPreset preset) async {
    _selected = SelectedBackground(preset: preset);
    await AppPreferences.instance.saveSelectedBackgroundSlug(preset.slug);
  }

  Future<void> loadSavedSelection({BackgroundCatalog? catalog}) async {
    final slug = await AppPreferences.instance.loadSelectedBackgroundSlug();
    if (slug == null) return;

    if (catalog != null) {
      for (final preset in catalog.all) {
        if (preset.slug == slug) {
          _selected = SelectedBackground(preset: preset);
          return;
        }
      }
    }

    final bundled = BundledBackgroundCatalog.findPresetBySlug(slug);
    if (bundled != null) {
      _selected = SelectedBackground(preset: bundled);
    }
  }

  void clearSelection() {
    _selected = null;
    AppPreferences.instance.clearSelectedBackgroundSlug();
  }

  Future<BackgroundCatalog> fetchCatalog() async {
    try {
      return mergeWithDefaultPresets(await _remote.fetchCatalog());
    } catch (_) {
      return BundledBackgroundCatalog.catalog;
    }
  }

  /// Bundled presets ship in the APK and must always be available offline.
  static BackgroundCatalog mergeWithDefaultPresets(BackgroundCatalog catalog) {
    if (catalog.presets.isNotEmpty) return catalog;

    final bundled = BundledBackgroundCatalog.catalog;
    return BackgroundCatalog(
      presets: bundled.presets,
      custom: catalog.custom,
      customBackgroundPriceUsd: catalog.customBackgroundPriceUsd > 0
          ? catalog.customBackgroundPriceUsd
          : bundled.customBackgroundPriceUsd,
    );
  }

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
