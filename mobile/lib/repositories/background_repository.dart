import 'dart:typed_data';

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

  Future<Uint8List> fetchImageBytes(String previewPath) async {
    final cached = _imageCache[previewPath];
    if (cached != null) return cached;

    final bytes = await _remote.fetchImageBytes(previewPath);
    final data = Uint8List.fromList(bytes);
    _imageCache[previewPath] = data;
    return data;
  }

  void clearImageCache() => _imageCache.clear();
}
