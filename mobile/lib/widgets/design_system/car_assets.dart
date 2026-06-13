/// BMW M4 Coupe (G82) server image paths with theme-aware color selection.
enum CarViewAngle {
  sideLeft,
  sideRight,
  front,
  rear,
  threeQuarterLeft,
  threeQuarterRight,
}

enum CarPaintVariant { white, black, neutral }

class CarAssets {
  CarAssets._();

  static const model = 'bmw_m4_g82';

  /// Dark theme → white car; light theme → black car.
  static CarPaintVariant paintForTheme({required bool isDark}) =>
      isDark ? CarPaintVariant.white : CarPaintVariant.black;

  static String path(
    CarViewAngle angle, {
    required bool isDark,
    CarPaintVariant? variant,
  }) {
    final paint = variant ?? paintForTheme(isDark: isDark);
    return _imageUrl(angle, paint);
  }

  static String neutralPath(CarViewAngle angle) => _imageUrl(angle, CarPaintVariant.neutral);

  static CarViewAngle fromBackgroundAngle(String? angle) {
    switch (angle) {
      case 'left':
        return CarViewAngle.sideLeft;
      case 'right':
        return CarViewAngle.sideRight;
      case 'front':
        return CarViewAngle.front;
      case 'rear':
        return CarViewAngle.rear;
      case 'three_quarter_left':
        return CarViewAngle.threeQuarterLeft;
      case 'three_quarter_right':
        return CarViewAngle.threeQuarterRight;
      default:
        return CarViewAngle.sideRight;
    }
  }

  static String _imageUrl(CarViewAngle angle, CarPaintVariant paint) =>
      '/cars/image/$model/${_fileStem(angle)}/${paint.name}';

  static String _fileStem(CarViewAngle angle) {
    switch (angle) {
      case CarViewAngle.sideLeft:
        return 'side_left';
      case CarViewAngle.sideRight:
        return 'side_right';
      case CarViewAngle.front:
        return 'front';
      case CarViewAngle.rear:
        return 'rear';
      case CarViewAngle.threeQuarterLeft:
        return 'three_quarter_left';
      case CarViewAngle.threeQuarterRight:
        return 'three_quarter_right';
    }
  }
}
