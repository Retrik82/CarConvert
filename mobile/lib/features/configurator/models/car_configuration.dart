import 'package:flutter/material.dart';

class CarConfiguration {
  final ExteriorColor exterior;
  final WheelStyle wheels;
  final InteriorStyle interior;
  final StudioEnvironment studio;

  const CarConfiguration({
    this.exterior = ExteriorColor.pearlWhite,
    this.wheels = WheelStyle.aero,
    this.interior = InteriorStyle.minimal,
    this.studio = StudioEnvironment.daylight,
  });

  CarConfiguration copyWith({
    ExteriorColor? exterior,
    WheelStyle? wheels,
    InteriorStyle? interior,
    StudioEnvironment? studio,
  }) {
    return CarConfiguration(
      exterior: exterior ?? this.exterior,
      wheels: wheels ?? this.wheels,
      interior: interior ?? this.interior,
      studio: studio ?? this.studio,
    );
  }

  Color get bodyColor => exterior.color;
}

enum ExteriorColor {
  pearlWhite('Pearl White', Color(0xFFF5F5F7)),
  obsidianBlack('Obsidian Black', Color(0xFF0A0A0C)),
  silverMetallic('Silver Metallic', Color(0xFFB8B8C0)),
  deepBlue('Deep Blue', Color(0xFF1A3A5C)),
  racingRed('Racing Red', Color(0xFF8B1A1A));

  final String label;
  final Color color;
  const ExteriorColor(this.label, this.color);
}

enum WheelStyle {
  aero('Aero 20"', 'Lightweight aero design'),
  sport('Sport 21"', 'Multi-spoke performance'),
  classic('Classic 19"', 'Timeless elegance'),
  forged('Forged 22"', 'Track-inspired');

  final String label;
  final String subtitle;
  const WheelStyle(this.label, this.subtitle);
}

enum InteriorStyle {
  minimal('Minimal Light', 'Clean Scandinavian cabin'),
  sport('Sport Dark', 'Alcantara & carbon accents'),
  luxury('Luxury Beige', 'Premium leather finish'),
  tech('Tech Black', 'Digital cockpit atmosphere');

  final String label;
  final String subtitle;
  const InteriorStyle(this.label, this.subtitle);
}

enum StudioEnvironment {
  daylight('Daylight Studio', 'Soft natural illumination'),
  showroom('Showroom White', 'Classic infinite backdrop'),
  dusk('Dusk Ambient', 'Warm evening atmosphere'),
  noir('Noir Studio', 'Dramatic low-key lighting');

  final String label;
  final String subtitle;
  const StudioEnvironment(this.label, this.subtitle);
}

enum ConfigStep { color, wheels, interior, studio, summary }

extension ConfigStepX on ConfigStep {
  int get index => ConfigStep.values.indexOf(this);
  ConfigStep? get next {
    final i = index + 1;
    return i < ConfigStep.values.length ? ConfigStep.values[i] : null;
  }

  ConfigStep? get previous {
    final i = index - 1;
    return i >= 0 ? ConfigStep.values[i] : null;
  }
}

class CarConfigurationController extends ChangeNotifier {
  CarConfiguration _config = const CarConfiguration();
  ConfigStep _step = ConfigStep.color;

  CarConfiguration get config => _config;
  ConfigStep get step => _step;

  void setExterior(ExteriorColor color) {
    _config = _config.copyWith(exterior: color);
    notifyListeners();
  }

  void setWheels(WheelStyle wheels) {
    _config = _config.copyWith(wheels: wheels);
    notifyListeners();
  }

  void setInterior(InteriorStyle interior) {
    _config = _config.copyWith(interior: interior);
    notifyListeners();
  }

  void setStudio(StudioEnvironment studio) {
    _config = _config.copyWith(studio: studio);
    notifyListeners();
  }

  void goToStep(ConfigStep step) {
    _step = step;
    notifyListeners();
  }

  void nextStep() {
    final n = _step.next;
    if (n != null) {
      _step = n;
      notifyListeners();
    }
  }

  void previousStep() {
    final p = _step.previous;
    if (p != null) {
      _step = p;
      notifyListeners();
    }
  }

  void reset() {
    _config = const CarConfiguration();
    _step = ConfigStep.color;
    notifyListeners();
  }
}
