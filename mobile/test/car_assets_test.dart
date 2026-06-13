import 'package:carconvert/widgets/design_system/car_assets.dart';
import 'package:carconvert/widgets/design_system/car_overlay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CarAssets', () {
    test('dark theme uses white paint variant', () {
      expect(
        CarAssets.path(CarViewAngle.sideRight, isDark: true),
        '/cars/image/bmw_m4_g82/side_right/white',
      );
    });

    test('light theme uses black paint variant', () {
      expect(
        CarAssets.path(CarViewAngle.sideRight, isDark: false),
        '/cars/image/bmw_m4_g82/side_right/black',
      );
    });

    test('paintForTheme maps dark to white and light to black', () {
      expect(CarAssets.paintForTheme(isDark: true), CarPaintVariant.white);
      expect(CarAssets.paintForTheme(isDark: false), CarPaintVariant.black);
    });

    test('fromBackgroundAngle maps server angle strings', () {
      expect(CarAssets.fromBackgroundAngle('left'), CarViewAngle.sideLeft);
      expect(CarAssets.fromBackgroundAngle('right'), CarViewAngle.sideRight);
      expect(CarAssets.fromBackgroundAngle('front'), CarViewAngle.front);
      expect(CarAssets.fromBackgroundAngle('rear'), CarViewAngle.rear);
      expect(
        CarAssets.fromBackgroundAngle('three_quarter_left'),
        CarViewAngle.threeQuarterLeft,
      );
      expect(
        CarAssets.fromBackgroundAngle('three_quarter_right'),
        CarViewAngle.threeQuarterRight,
      );
      expect(CarAssets.fromBackgroundAngle(null), CarViewAngle.sideRight);
      expect(CarAssets.fromBackgroundAngle('unknown'), CarViewAngle.sideRight);
    });

    test('neutral path for configurator tinting', () {
      expect(
        CarAssets.neutralPath(CarViewAngle.sideRight),
        '/cars/image/bmw_m4_g82/side_right/neutral',
      );
    });

    test('explicit variant overrides theme', () {
      expect(
        CarAssets.path(
          CarViewAngle.front,
          isDark: true,
          variant: CarPaintVariant.black,
        ),
        '/cars/image/bmw_m4_g82/front/black',
      );
    });
  });

  group('CarOverlay', () {
    test('hides car for interior angle', () {
      expect(CarOverlay.supportsBackgroundAngle('interior'), isFalse);
      expect(CarOverlay.supportsBackgroundAngle('front'), isTrue);
    });
  });
}
