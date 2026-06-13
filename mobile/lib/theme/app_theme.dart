import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';

/// Backward-compatible facade. Prefer `context.tokens` in new code.
class AppTheme {
  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFF4F2EF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF8F7F5);
  static const textPrimary = Color(0xFF0D0D0F);
  static const textSecondary = Color(0xFF5C5C66);
  static const textTertiary = Color(0xFF9494A0);
  static const accent = Color(0xFF0D0D0F);
  static const border = Color(0xFFE4E2DE);
  static const borderFocus = Color(0xFF0D0D0F);
  static const error = Color(0xFFC0392B);
  static const success = Color(0xFF1B7F4A);

  static const spacingScreenH = 24.0;
  static const spacingSection = 32.0;
  static const spacingElement = 16.0;

  static const radiusCard = 24.0;
  static const radiusButton = 20.0;
  static const radiusInput = 16.0;

  static const durationShort = Duration(milliseconds: 250);
  static const durationMedium = Duration(milliseconds: 350);
  static const curveStandard = Curves.easeInOutCubic;

  static TextStyle textStyle({
    required double fontSize,
    required FontWeight fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return AppTokens.light.textStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static BoxDecoration cardDecoration({Color? color, bool showBorder = true}) {
    return AppTokens.light.cardDecoration(color: color);
  }

  static BoxDecoration get cardDecorationDefault => AppTokens.light.cardDecoration();

  static ThemeData get theme => throw UnsupportedError('Use AppThemeBuilder via MaterialApp');

  static ThemeData get dark => throw UnsupportedError('Use AppThemeBuilder via MaterialApp');
}
