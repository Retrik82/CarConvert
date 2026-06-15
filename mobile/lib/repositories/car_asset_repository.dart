import 'dart:typed_data';

import '../core/assets/bundled_assets.dart';
import '../core/assets/local_asset_loader.dart';
import '../datasource/remote/car_asset_remote_datasource.dart';
import '../widgets/design_system/car_assets.dart';
import 'auth_repository.dart';

class CarAssetRepository {
  CarAssetRepository._() {
    _remote = CarAssetRemoteDataSource(AuthRepository.instance.httpClient);
  }

  static final CarAssetRepository instance = CarAssetRepository._();

  late final CarAssetRemoteDataSource _remote;

  final Map<String, Uint8List> _imageCache = {};

  Future<Uint8List> fetchImageBytes(String imagePath) async {
    final cached = _imageCache[imagePath];
    if (cached != null) return cached;

    final bundledPath = BundledAssets.carAssetPathFromApiPath(imagePath);
    if (bundledPath != null) {
      final bytes = await LocalAssetLoader.loadBytes(bundledPath);
      _imageCache[imagePath] = bytes;
      return bytes;
    }

    final bytes = await _remote.fetchImageBytes(imagePath);
    final data = Uint8List.fromList(bytes);
    _imageCache[imagePath] = data;
    return data;
  }

  Future<void> prefetchDefaults() async {
    const views = [
      CarViewAngle.sideRight,
      CarViewAngle.front,
      CarViewAngle.threeQuarterLeft,
    ];
    await Future.wait([
      for (final view in views) ...[
        fetchImageBytes(CarAssets.path(view, isDark: true)),
        fetchImageBytes(CarAssets.path(view, isDark: false)),
      ],
    ], eagerError: false);
  }

  void clearImageCache() {
    _imageCache.clear();
    LocalAssetLoader.clearCache();
  }
}
