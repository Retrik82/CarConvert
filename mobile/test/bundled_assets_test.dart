import 'package:carconvert/core/assets/bundled_assets.dart';
import 'package:carconvert/widgets/design_system/car_assets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BundledAssets', () {
    test('maps car API paths to bundled PNG paths', () {
      expect(
        BundledAssets.carAssetPathFromApiPath('/cars/image/bmw_m4_g82/side_right/white'),
        'assets/cars/bmw_m4_g82/side_right_white.png',
      );
    });

    test('maps preset slug and angle to bundled JPG paths', () {
      expect(
        BundledAssets.presetBackgroundAssetPath('gray-showroom', 'three_quarter_left'),
        'assets/backgrounds/presets/gray-showroom/three_quarter_left.jpg',
      );
      expect(
        BundledAssets.presetBackgroundAssetPath('auto-workshop', 'interior'),
        'assets/backgrounds/presets/auto-workshop/interior.jpg',
      );
    });

    test('returns null for unknown preset', () {
      expect(BundledAssets.presetBackgroundAssetPath('custom', 'front'), isNull);
    });

    test('carAssetPath builds filename from angle and paint', () {
      expect(
        BundledAssets.carAssetPath(CarViewAngle.front, CarPaintVariant.black),
        'assets/cars/bmw_m4_g82/front_black.png',
      );
    });
  });
}
