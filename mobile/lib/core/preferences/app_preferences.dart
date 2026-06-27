import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences._();
  static final instance = AppPreferences._();

  static const _themeKey = 'app_theme_mode';
  static const _localeKey = 'app_locale';
  static const _selectedBackgroundSlugKey = 'selected_background_slug';

  Future<ThemeMode> loadThemeMode() async {
    return ThemeMode.light;
  }

  Future<String?> loadSelectedBackgroundSlug() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedBackgroundSlugKey);
  }

  Future<void> saveSelectedBackgroundSlug(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedBackgroundSlugKey, slug);
  }

  Future<void> clearSelectedBackgroundSlug() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedBackgroundSlugKey);
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await prefs.setString(_themeKey, value);
  }

  Future<Locale?> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code == null) return null;
    return Locale(code);
  }

  Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }
}
