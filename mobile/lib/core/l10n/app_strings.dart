import 'package:flutter/material.dart';

import 'strings_de.dart';
import 'strings_en.dart';
import 'strings_ru.dart';

enum AppLanguage {
  en,
  ru,
  de;

  Locale get locale => Locale(name);

  String get label => switch (this) {
        AppLanguage.en => 'EN',
        AppLanguage.ru => 'RU',
        AppLanguage.de => 'DE',
      };

  String get fullName => switch (this) {
        AppLanguage.en => 'English',
        AppLanguage.ru => 'Русский',
        AppLanguage.de => 'Deutsch',
      };

  static AppLanguage fromLocale(Locale locale) {
    return AppLanguage.values.firstWhere(
      (l) => l.name == locale.languageCode,
      orElse: () => AppLanguage.en,
    );
  }
}

abstract class AppStrings {
  String get appName;
  String get appTagline;

  // Onboarding
  String get welcomeTitle;
  String get welcomeSubtitle;
  String get continueWithEmail;
  String get continueWithToken;
  String get companyLogin;

  // Auth
  String get login;
  String get register;
  String get forgotPassword;
  String get emailOrUsername;
  String get password;
  String get createAccount;
  String get resetPassword;
  String get backToLogin;

  // Dashboard
  String greeting(String name);
  String get dashboardSubtitle;
  String get configureStudio;
  String get takePhoto;
  String get fromGallery;
  String get changeBackground;
  String get chooseBackground;
  String get backgroundSelected;
  String get startCapture;

  // Navigation
  String get navHome;
  String get navCars;
  String get navProfile;

  // Configurator
  String get configTitle;
  String get stepColor;
  String get stepWheels;
  String get stepInterior;
  String get stepStudio;
  String get stepSummary;
  String get selectColor;
  String get selectWheels;
  String get selectInterior;
  String get selectStudio;
  String get yourConfiguration;
  String get continueStep;
  String get confirmAndCapture;
  String get estimatedPrice;

  // Profile
  String get profile;
  String get settings;
  String get appearance;
  String get language;
  String get theme;
  String get themeLight;
  String get themeDark;
  String get editProfile;
  String get logout;
  String get logoutConfirmTitle;
  String get logoutConfirmBody;
  String get cancel;
  String get confirm;

  // States
  String get loading;
  String get retry;
  String get emptyCars;
  String get emptyCarsSubtitle;
  String get errorGeneric;

  static AppStrings of(Locale locale) {
    return switch (AppLanguage.fromLocale(locale)) {
      AppLanguage.en => StringsEn(),
      AppLanguage.ru => StringsRu(),
      AppLanguage.de => StringsDe(),
    };
  }
}

extension AppStringsContext on BuildContext {
  AppStrings get strings {
    final locale = Localizations.maybeLocaleOf(this) ?? const Locale('en');
    return AppStrings.of(locale);
  }
}
