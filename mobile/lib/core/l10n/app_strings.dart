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
  String get loginNoAccount;
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

  // Backgrounds
  String get backgroundsTitle;
  String get backgroundsIntro;
  String get sharedBackgrounds;
  String get yourBackgrounds;
  String get selectBackground;
  String get useThisBackground;
  String get personal;

  // Capture
  String get captureTitle;
  String get captureCamera;
  String get captureGallery;
  String get uploadFromGallery;
  String get selectGalleryPhoto;
  String get advisorConnecting;
  String get advisorPointCamera;
  String get advisorPerfectFrame;
  String get advisorLowLight;
  String get advisorMoveLeft;
  String get advisorMoveRight;
  String get advisorMoveBack;
  String get advisorMoveCloser;
  String get advisorAlignCar;
  String get advisorImproveFocus;
  String confidenceLabel(int percent);
  String get qualityFraming;
  String get qualityLighting;
  String get qualityFocus;

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

  // Processing & results
  String get processingTitle;
  String get processingQueued;
  String get processingRendering;
  String get renderResultTitle;
  String get saveToMyCars;
  String get savedToMyCars;
  String get downloadPhoto;
  String get photoSaved;
  String get photoSaveFailed;
  String get deleteRender;
  String get reRender;
  String get beforeLabel;
  String get afterLabel;
  String get pinchToZoom;

  // Background picker UX
  String get backgroundAnglesTitle;
  String get backgroundGenerationPrompt;
  String get backgroundTapToExpand;

  // Gallery / My Cars
  String get rename;
  String get renameCar;
  String get createCar;
  String get renameRender;
  String get renderName;
  String get renderNameHint;
  String get carName;
  String get carNameHint;
  String get renderHistory;
  String get addRender;
  String get deleteCar;
  String get preview;

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
