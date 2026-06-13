import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  final Color background;
  final Color backgroundElevated;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceGlass;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color accentMuted;
  final Color onAccent;
  final Color border;
  final Color borderSubtle;
  final Color error;
  final Color success;
  final Color shadow;
  final Color glow;
  final Color heroAmbient;
  final Color heroFloor;
  final Color heroPodium;
  final Color carBodyLight;
  final Color carBodyDark;
  final Color carHighlight;
  final Color carReflection;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> elevatedShadow;
  final bool isDark;

  const AppTokens({
    required this.background,
    required this.backgroundElevated,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceGlass,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentMuted,
    required this.onAccent,
    required this.border,
    required this.borderSubtle,
    required this.error,
    required this.success,
    required this.shadow,
    required this.glow,
    required this.heroAmbient,
    required this.heroFloor,
    required this.heroPodium,
    required this.carBodyLight,
    required this.carBodyDark,
    required this.carHighlight,
    required this.carReflection,
    required this.cardShadow,
    required this.elevatedShadow,
    required this.isDark,
  });

  static const light = AppTokens(
    background: Color(0xFFF4F2EF),
    backgroundElevated: Color(0xFFEBE8E4),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF8F7F5),
    surfaceGlass: Color(0xCCFFFFFF),
    textPrimary: Color(0xFF0D0D0F),
    textSecondary: Color(0xFF5C5C66),
    textTertiary: Color(0xFF9494A0),
    accent: Color(0xFF0D0D0F),
    accentMuted: Color(0xFF2A2A32),
    onAccent: Color(0xFFFFFFFF),
    border: Color(0xFFE4E2DE),
    borderSubtle: Color(0xFFF0EEEA),
    error: Color(0xFFC0392B),
    success: Color(0xFF1B7F4A),
    shadow: Color(0x1A0D0D0F),
    glow: Color(0x33B8B4AC),
    heroAmbient: Color(0xFFE8E4DE),
    heroFloor: Color(0xFFD8D4CE),
    heroPodium: Color(0xFFF0EEEA),
    carBodyLight: Color(0xFFF5F5F7),
    carBodyDark: Color(0xFFD8D8DC),
    carHighlight: Color(0xFFFFFFFF),
    carReflection: Color(0x66FFFFFF),
    cardShadow: [
      BoxShadow(
        color: Color(0x140D0D0F),
        blurRadius: 32,
        offset: Offset(0, 12),
        spreadRadius: -4,
      ),
      BoxShadow(
        color: Color(0x0A0D0D0F),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
    elevatedShadow: [
      BoxShadow(
        color: Color(0x200D0D0F),
        blurRadius: 48,
        offset: Offset(0, 20),
        spreadRadius: -8,
      ),
    ],
    isDark: false,
  );

  static const dark = AppTokens(
    background: Color(0xFF08080A),
    backgroundElevated: Color(0xFF121216),
    surface: Color(0xFF16161C),
    surfaceMuted: Color(0xFF1C1C24),
    surfaceGlass: Color(0x9916161C),
    textPrimary: Color(0xFFF2F2F4),
    textSecondary: Color(0xFF9898A4),
    textTertiary: Color(0xFF646470),
    accent: Color(0xFFF2F2F4),
    accentMuted: Color(0xFFC8C8D0),
    onAccent: Color(0xFF08080A),
    border: Color(0xFF2A2A34),
    borderSubtle: Color(0xFF1E1E26),
    error: Color(0xFFE57373),
    success: Color(0xFF66BB6A),
    shadow: Color(0x66000000),
    glow: Color(0x33FFFFFF),
    heroAmbient: Color(0xFF1A1A22),
    heroFloor: Color(0xFF0E0E12),
    heroPodium: Color(0xFF22222C),
    carBodyLight: Color(0xFF3A3A42),
    carBodyDark: Color(0xFF0A0A0C),
    carHighlight: Color(0xFF6A6A74),
    carReflection: Color(0x33FFFFFF),
    cardShadow: [
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 24,
        offset: Offset(0, 8),
        spreadRadius: -4,
      ),
    ],
    elevatedShadow: [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 40,
        offset: Offset(0, 16),
        spreadRadius: -8,
      ),
    ],
    isDark: true,
  );

  TextStyle textStyle({
    required double fontSize,
    required FontWeight fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? textPrimary,
      height: height ?? _lineHeight(fontSize),
      letterSpacing: letterSpacing,
    );
  }

  static double _lineHeight(double fontSize) {
    if (fontSize >= 28) return 1.2;
    if (fontSize >= 20) return 1.3;
    return 1.45;
  }

  TextTheme get textTheme => TextTheme(
        displayLarge: textStyle(fontSize: 36, fontWeight: FontWeight.w600, letterSpacing: -0.8),
        displayMedium: textStyle(fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.6),
        headlineMedium: textStyle(fontSize: 24, fontWeight: FontWeight.w500, letterSpacing: -0.3),
        titleLarge: textStyle(fontSize: 20, fontWeight: FontWeight.w500),
        titleMedium: textStyle(fontSize: 18, fontWeight: FontWeight.w500),
        bodyLarge: textStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary),
        bodyMedium: textStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary),
        bodySmall: textStyle(fontSize: 13, fontWeight: FontWeight.w400, color: textTertiary),
        labelLarge: textStyle(fontSize: 16, fontWeight: FontWeight.w500, color: onAccent),
      );

  BoxDecoration cardDecoration({Color? color, bool elevated = false}) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
      border: Border.all(color: border.withValues(alpha: isDark ? 0.6 : 0.8)),
      boxShadow: elevated ? elevatedShadow : cardShadow,
    );
  }

  @override
  AppTokens copyWith({
    Color? background,
    Color? backgroundElevated,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceGlass,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? accentMuted,
    Color? onAccent,
    Color? border,
    Color? borderSubtle,
    Color? error,
    Color? success,
    Color? shadow,
    Color? glow,
    Color? heroAmbient,
    Color? heroFloor,
    Color? heroPodium,
    Color? carBodyLight,
    Color? carBodyDark,
    Color? carHighlight,
    Color? carReflection,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? elevatedShadow,
    bool? isDark,
  }) {
    return AppTokens(
      background: background ?? this.background,
      backgroundElevated: backgroundElevated ?? this.backgroundElevated,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceGlass: surfaceGlass ?? this.surfaceGlass,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      accentMuted: accentMuted ?? this.accentMuted,
      onAccent: onAccent ?? this.onAccent,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      error: error ?? this.error,
      success: success ?? this.success,
      shadow: shadow ?? this.shadow,
      glow: glow ?? this.glow,
      heroAmbient: heroAmbient ?? this.heroAmbient,
      heroFloor: heroFloor ?? this.heroFloor,
      heroPodium: heroPodium ?? this.heroPodium,
      carBodyLight: carBodyLight ?? this.carBodyLight,
      carBodyDark: carBodyDark ?? this.carBodyDark,
      carHighlight: carHighlight ?? this.carHighlight,
      carReflection: carReflection ?? this.carReflection,
      cardShadow: cardShadow ?? this.cardShadow,
      elevatedShadow: elevatedShadow ?? this.elevatedShadow,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppTokens lerp(covariant ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      background: Color.lerp(background, other.background, t)!,
      backgroundElevated: Color.lerp(backgroundElevated, other.backgroundElevated, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceGlass: Color.lerp(surfaceGlass, other.surfaceGlass, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      heroAmbient: Color.lerp(heroAmbient, other.heroAmbient, t)!,
      heroFloor: Color.lerp(heroFloor, other.heroFloor, t)!,
      heroPodium: Color.lerp(heroPodium, other.heroPodium, t)!,
      carBodyLight: Color.lerp(carBodyLight, other.carBodyLight, t)!,
      carBodyDark: Color.lerp(carBodyDark, other.carBodyDark, t)!,
      carHighlight: Color.lerp(carHighlight, other.carHighlight, t)!,
      carReflection: Color.lerp(carReflection, other.carReflection, t)!,
      cardShadow: cardShadow,
      elevatedShadow: elevatedShadow,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
}
