import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/admin_shell.dart';
import 'screens/login_screen.dart';
import 'screens/user_shell.dart';
import 'repositories/auth_repository.dart';
import 'repositories/car_repository.dart';
import 'theme/app_theme.dart';
import 'widgets/app_logo.dart';

enum AppDestination { login, userHome, adminHome }

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLogo(showTagline: true),
            SizedBox(height: 48),
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3),
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
    if (!loggedIn && mounted && _ready && _destination != AppDestination.login) {
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
    if (mounted) setState(() => _destination = AppDestination.login);
  }

  void _onLogout() {
    unawaited(_handleLoggedOut());
  }

  Widget _buildHome() {
    if (!_ready) return const SplashScreen();

    switch (_destination) {
      case AppDestination.login:
        return LoginScreen(onLoggedIn: _onAuthSuccess);
      case AppDestination.userHome:
        return UserShell(onLogout: _onLogout);
      case AppDestination.adminHome:
        return AdminShell(onLogout: _onLogout);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RenderWheels',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: _buildHome(),
    );
  }
}
