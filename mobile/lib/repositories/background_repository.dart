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
      return mergeWithDefaultPresets(BundledBackgroundCatalog.catalog);
    }
  }

  /// Shared presets always ship in the APK — keep bundled slugs/variants for UI.
  static List<BackgroundPreset> sharedPresetsFrom(BackgroundCatalog? remoteCatalog) {
    final remotePresets = remoteCatalog?.presets ?? const [];
    final remoteBySlug = <String, BackgroundPreset>{};

    for (final remote in remotePresets) {
      remoteBySlug[remote.slug] = remote;
      for (final bundled in BundledBackgroundCatalog.catalog.presets) {
        if (remote.name == bundled.name) {
          remoteBySlug.putIfAbsent(bundled.slug, () => remote);
        }
      }
    }

    return [
      for (final bundled in BundledBackgroundCatalog.catalog.presets)
        _mergePreset(bundled, remoteBySlug[bundled.slug]),
    ];
  }

  /// Bundled presets ship in the APK and must always be available offline.
  static BackgroundCatalog mergeWithDefaultPresets(BackgroundCatalog catalog) {
    final bundled = BundledBackgroundCatalog.catalog;

    return BackgroundCatalog(
      presets: sharedPresetsFrom(catalog),
      custom: catalog.custom,
      customBackgroundPriceUsd: catalog.customBackgroundPriceUsd > 0
          ? catalog.customBackgroundPriceUsd
          : bundled.customBackgroundPriceUsd,
    );
  }

  static BackgroundPreset _mergePreset(BackgroundPreset local, BackgroundPreset? remote) {
    if (remote == null) return local;
    return BackgroundPreset(
      id: remote.id,
      slug: local.slug,
      name: remote.name.isNotEmpty ? remote.name : local.name,
      description: remote.description ?? local.description,
      generationPrompt: remote.generationPrompt ?? local.generationPrompt,
      previewUrl: local.previewUrl ?? remote.previewUrl,
      variants: local.variants,
      isCustom: false,
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
