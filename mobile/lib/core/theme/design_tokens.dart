import 'package:flutter/material.dart';

/// Shared spacing, radii, and motion constants — theme-independent.
abstract final class DesignTokens {
  static const spacing4 = 4.0;
  static const spacing8 = 8.0;
  static const spacing12 = 12.0;
  static const spacing16 = 16.0;
  static const spacing24 = 24.0;
  static const spacing32 = 32.0;
  static const spacing48 = 48.0;

  static const screenPaddingH = 24.0;
  static const minTapTarget = 48.0;

  static const radiusCard = 24.0;
  static const radiusButton = 20.0;
  static const radiusInput = 16.0;
  static const radiusChip = 12.0;
  static const radiusHero = 28.0;

  static const durationFast = Duration(milliseconds: 200);
  static const durationNormal = Duration(milliseconds: 350);
  static const durationSlow = Duration(milliseconds: 550);
  static const durationTheme = Duration(milliseconds: 650);

  static const curveStandard = Curves.easeInOutCubic;
  static const curveEmphasized = Curves.easeOutCubic;
  static const curveDecelerate = Curves.decelerate;
}
