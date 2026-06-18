import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';

/// Backward-compatible facade. Prefer `context.tokens` in new code.
class AppTheme {
  static const white = Color(0xFFFFFFFF);
  static const background = DesignTokens.backgroundWhite;
  static const surface = DesignTokens.backgroundWhite;
  static const surfaceMuted = Color(0xFFF1F5F9);
  static const textPrimary = DesignTokens.textDark;
  static const textSecondary = DesignTokens.textMuted;
  static const textTertiary = Color(0xFF94A3B8);
  static const accent = DesignTokens.primaryBlue;
  static const border = DesignTokens.borderLight;
  static const borderFocus = DesignTokens.primaryBlue;
  static const error = Color(0xFFDC2626);
  static const success = Color(0xFF16A34A);

  static const spacingScreenH = 24.0;
  static const spacingSection = 32.0;
  static const spacingElement = 16.0;

  static const radiusCard = 24.0;
  static const radiusButton = 16.0;
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
