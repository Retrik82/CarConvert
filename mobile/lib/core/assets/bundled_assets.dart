import '../../widgets/design_system/car_assets.dart';

/// Bundled image paths shipped inside the Flutter app (no network fetch).
class BundledAssets {
  BundledAssets._();

  static const carRoot = 'assets/cars/bmw_m4_g82';
  static const backgroundRoot = 'assets/backgrounds/presets';
  static const brandingRoot = 'assets/branding';
  static const marketingRoot = 'assets/marketing';

  static const presetSlugs = {'gray-showroom', 'auto-workshop'};

  static const presetAngles = {
    'left',
    'right',
    'front',
    'rear',
    'interior',
    'three_quarter_left',
    'three_quarter_right',
  };

  static const appLogo = '$brandingRoot/app_logo.png';
  static const authHero = '$brandingRoot/auth_hero.jpg';
  static const carStreetOutdoor = '$marketingRoot/car_street_outdoor.jpg';
  static const carShowroomGray = '$marketingRoot/car_showroom_gray.jpg';
  static const carWorkshopStudio = '$marketingRoot/car_workshop_studio.jpg';

  /// Cohesive before/after marketing image for the selected preset slug.
  static String afterMarketingImageForPreset(String? slug) {
    if (slug == 'auto-workshop') return carWorkshopStudio;
    return carShowroomGray;
  }

  static String? carAssetPath(CarViewAngle angle, CarPaintVariant paint) {
    return '$carRoot/${_carStem(angle)}_${paint.name}.png';
  }

  static String? carAssetPathFromApiPath(String apiPath) {
    final parts = apiPath.split('/');
    if (parts.length < 5 || parts[1] != 'cars' || parts[2] != 'image') {
      return null;
    }
    final view = parts[4];
    final paint = parts.length > 5 ? parts[5] : 'white';
    return '$carRoot/${view}_$paint.png';
  }

  static String? presetBackgroundAssetPath(String slug, String angle) {
    if (!presetSlugs.contains(slug) || !presetAngles.contains(angle)) {
      return null;
    }
    return '$backgroundRoot/$slug/$angle.jpg';
  }

  static String _carStem(CarViewAngle angle) {
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
