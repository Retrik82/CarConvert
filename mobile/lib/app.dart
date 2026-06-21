import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/app_strings.dart';
import 'core/theme/app_theme_builder.dart';
import 'core/theme/app_tokens.dart';
import 'core/theme/design_tokens.dart';
import 'screens/admin_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/user_shell.dart';
import 'repositories/auth_repository.dart';
import 'repositories/car_asset_repository.dart';
import 'repositories/car_repository.dart';
import 'widgets/app_logo.dart';

enum AppDestination { login, userHome, adminHome }

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>() ?? AppTokens.light;

    return Scaffold(
      backgroundColor: tokens.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogo(iconSize: 56, titleSize: 32, useImageLogo: true),
            const SizedBox(height: DesignTokens.spacing48),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: tokens.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RenderWheelsApp extends StatefulWidget {
  const RenderWheelsApp({super.key});

  @override
  State<RenderWheelsApp> createState() => _RenderWheelsAppState();
}

class _RenderWheelsAppState extends State<RenderWheelsApp> {
  static const _bootstrapTimeout = Duration(seconds: 5);

  final _settings = AppSettingsController();

  bool _ready = false;
  AppDestination _destination = AppDestination.login;

  @override
  void initState() {
    super.initState();
    AuthRepository.instance.addListener(_onAuthStateChanged);
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    AuthRepository.instance.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _settings.load();
    unawaited(CarAssetRepository.instance.prefetchDefaults());

    var next = AppDestination.login;
    try {
      await AuthRepository.instance.loadStoredSession().timeout(_bootstrapTimeout);
      if (AuthRepository.instance.isLoggedIn) {
        final isAdmin = AuthRepository.instance.currentUser?.isAdmin ?? false;
        next = isAdmin ? AppDestination.adminHome : AppDestination.userHome;
      }
    } catch (_) {
      next = AppDestination.login;
    } finally {
      if (mounted) {
        setState(() {
          _destination = next;
          _ready = true;
        });
      }
    }

    if (next != AppDestination.login) {
      unawaited(_prepareLoggedInSession());
    }
  }

  Future<void> _prepareLoggedInSession() async {
    try {
      await AuthRepository.instance.refreshAccessToken().timeout(const Duration(seconds: 20));
    } catch (_) {}
    try {
      await CarRepository.instance.load();
    } catch (_) {}
  }

  void _onAuthStateChanged(bool loggedIn) {
    if (!mounted || !_ready) return;

    if (loggedIn && _destination == AppDestination.login) {
      unawaited(_onAuthSuccess());
      return;
    }

    if (!loggedIn && _destination != AppDestination.login) {
      unawaited(_handleLoggedOut());
    }
  }

  Future<void> _onAuthSuccess() async {
    if (!mounted) return;
    final isAdmin = AuthRepository.instance.currentUser?.isAdmin ?? false;
    final next = isAdmin ? AppDestination.adminHome : AppDestination.userHome;
    setState(() => _destination = next);
    unawaited(CarRepository.instance.load());
  }

  Future<void> _handleLoggedOut() async {
    await CarRepository.instance.clear();
    CarAssetRepository.instance.clearImageCache();
    if (mounted) setState(() => _destination = AppDestination.login);
  }

  void _onLogout() {
    unawaited(_handleLoggedOut());
  }

  Widget _buildHome() {
    if (!_ready) return const SplashScreen();

    switch (_destination) {
      case AppDestination.login:
        return OnboardingScreen(settings: _settings, onLoggedIn: _onAuthSuccess);
      case AppDestination.userHome:
        return UserShell(settings: _settings, onLogout: _onLogout);
      case AppDestination.adminHome:
        return AdminShell(onLogout: _onLogout);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'RenderWheels',
          debugShowCheckedModeBanner: false,
          locale: _settings.locale,
          supportedLocales: AppLanguage.values.map((l) => l.locale).toList(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppThemeBuilder.light,
          themeMode: ThemeMode.light,
          themeAnimationDuration: DesignTokens.durationTheme,
          themeAnimationCurve: DesignTokens.curveStandard,
          home: _buildHome(),
        );
      },
    );
  }
}
