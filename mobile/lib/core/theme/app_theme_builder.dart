import 'package:flutter/material.dart';

import '../preferences/app_preferences.dart';
import 'app_tokens.dart';
import 'design_tokens.dart';
import 'page_transitions.dart';

class AppThemeBuilder {
  static ThemeData build(AppTokens tokens) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: tokens.isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: tokens.background,
      colorScheme: ColorScheme(
        brightness: tokens.isDark ? Brightness.dark : Brightness.light,
        primary: tokens.accent,
        onPrimary: tokens.onAccent,
        secondary: tokens.accentMuted,
        onSecondary: tokens.onAccent,
        surface: tokens.surface,
        onSurface: tokens.textPrimary,
        error: tokens.error,
        onError: tokens.onAccent,
      ),
      textTheme: tokens.textTheme,
      fontFamily: tokens.textTheme.bodyLarge?.fontFamily,
      extensions: [tokens],
      splashFactory: InkRipple.splashFactory,
      splashColor: tokens.textPrimary.withValues(alpha: 0.06),
      highlightColor: tokens.textPrimary.withValues(alpha: 0.04),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: tokens.textStyle(fontSize: 18, fontWeight: FontWeight.w500),
        iconTheme: IconThemeData(color: tokens.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: DesignTokens.spacing16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
          side: BorderSide(color: tokens.border.withValues(alpha: 0.7)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.surface,
        elevation: 0,
        height: 72,
        indicatorColor: tokens.accentMuted.withValues(alpha: tokens.isDark ? 0.4 : 1),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return tokens.textStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? tokens.accent : tokens.textTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? tokens.accent : tokens.textTertiary,
            size: 24,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        labelStyle: tokens.textStyle(fontSize: 14, fontWeight: FontWeight.w400, color: tokens.textSecondary),
        hintStyle: tokens.textStyle(fontSize: 16, fontWeight: FontWeight.w400, color: tokens.textTertiary),
        errorStyle: tokens.textStyle(fontSize: 13, fontWeight: FontWeight.w400, color: tokens.error),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: BorderSide(color: tokens.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: BorderSide(color: tokens.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: BorderSide(color: tokens.error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.accent,
          foregroundColor: tokens.onAccent,
          disabledBackgroundColor: tokens.textTertiary.withValues(alpha: 0.25),
          disabledForegroundColor: tokens.onAccent.withValues(alpha: 0.6),
          minimumSize: const Size.fromHeight(DesignTokens.minTapTarget + 8),
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing24, vertical: DesignTokens.spacing16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusButton)),
          textStyle: tokens.textStyle(fontSize: 16, fontWeight: FontWeight.w500, color: tokens.onAccent),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          minimumSize: const Size.fromHeight(DesignTokens.minTapTarget + 8),
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing24, vertical: DesignTokens.spacing16),
          side: BorderSide(color: tokens.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusButton)),
          textStyle: tokens.textStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          textStyle: tokens.textStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: tokens.accent),
      dividerTheme: DividerThemeData(color: tokens.border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.isDark ? tokens.surfaceMuted : tokens.textPrimary,
        contentTextStyle: tokens.textStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: tokens.isDark ? tokens.textPrimary : tokens.onAccent,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusInput)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusHero)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusCard)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get light => build(AppTokens.light);
  static ThemeData get dark => build(AppTokens.dark);
}

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({
    ThemeMode themeMode = ThemeMode.system,
    Locale locale = const Locale('en'),
  })  : _themeMode = themeMode,
        _locale = locale;

  ThemeMode _themeMode;
  Locale _locale;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  bool get isDarkModeExplicit => _themeMode == ThemeMode.dark;

  ThemeData themeFor(Brightness platformBrightness) {
    final dark = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system && platformBrightness == Brightness.dark);
    return AppThemeBuilder.build(dark ? AppTokens.dark : AppTokens.light);
  }

  Future<void> load() async {
    final prefs = AppPreferences.instance;
    _themeMode = await prefs.loadThemeMode();
    _locale = await prefs.loadLocale() ?? const Locale('en');
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await AppPreferences.instance.saveThemeMode(mode);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final next = isDarkModeExplicit ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    await AppPreferences.instance.saveLocale(locale);
    notifyListeners();
  }
}
