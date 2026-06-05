import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Scandinavian minimal premium design system.
class AppTheme {
  // — Colors —
  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFFAFAFA);

  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF666666);
  static const textTertiary = Color(0xFF999999);

  /// Monochrome accent: active states, selection, key actions.
  static const accent = Color(0xFF111111);

  static const border = Color(0xFFE8E8E8);
  static const borderFocus = Color(0xFF111111);
  static const error = Color(0xFFC62828);
  static const success = Color(0xFF2E7D32);

  // — Spacing —
  static const spacingScreenH = 24.0;
  static const spacingSection = 32.0;
  static const spacingElement = 16.0;

  // — Radii —
  static const radiusCard = 22.0;
  static const radiusButton = 18.0;
  static const radiusInput = 16.0;

  // — Motion —
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
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? textPrimary,
      height: height ?? _lineHeight(fontSize),
      letterSpacing: letterSpacing,
    );
  }

  static double _lineHeight(double fontSize) {
    if (fontSize >= 28) return 1.25;
    if (fontSize >= 20) return 1.35;
    return 1.5;
  }

  static TextTheme get _textTheme => TextTheme(
        displayLarge: textStyle(fontSize: 32, fontWeight: FontWeight.w600, color: textPrimary),
        headlineMedium: textStyle(fontSize: 24, fontWeight: FontWeight.w500, color: textPrimary),
        titleMedium: textStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textPrimary),
        bodyLarge: textStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary),
        bodyMedium: textStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary),
        bodySmall: textStyle(fontSize: 13, fontWeight: FontWeight.w400, color: textTertiary),
        labelLarge: textStyle(fontSize: 16, fontWeight: FontWeight.w500, color: white),
      );

  static BoxDecoration cardDecoration({Color? color, bool showBorder = true}) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(radiusCard),
      border: showBorder ? Border.all(color: AppTheme.border.withValues(alpha: 0.6)) : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration get cardDecorationDefault => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radiusCard),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: accent,
        onPrimary: white,
        secondary: textSecondary,
        onSecondary: white,
        surface: surface,
        onSurface: textPrimary,
        error: error,
        onError: white,
      ),
      textTheme: _textTheme,
      fontFamily: GoogleFonts.inter().fontFamily,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textPrimary),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: spacingElement),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: white,
        elevation: 0,
        height: 72,
        indicatorColor: surfaceMuted,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            color: selected ? textPrimary : textTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? textPrimary : textTertiary,
            size: 24,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        labelStyle: textStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary),
        hintStyle: textStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textTertiary),
        errorStyle: textStyle(fontSize: 13, fontWeight: FontWeight.w400, color: error),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: white,
          disabledBackgroundColor: textTertiary.withValues(alpha: 0.3),
          disabledForegroundColor: white.withValues(alpha: 0.7),
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          textStyle: textStyle(fontSize: 16, fontWeight: FontWeight.w500, color: white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          textStyle: textStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          textStyle: textStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusButton)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: textStyle(fontSize: 14, fontWeight: FontWeight.w400, color: white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusInput)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      splashFactory: InkRipple.splashFactory,
      splashColor: textPrimary.withValues(alpha: 0.06),
      highlightColor: textPrimary.withValues(alpha: 0.04),
    );
  }

  /// @deprecated Use [theme]. Kept for gradual migration.
  static ThemeData get dark => theme;
}
