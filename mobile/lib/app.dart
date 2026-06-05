import 'package:flutter/material.dart';

import 'screens/admin_shell.dart';
import 'screens/login_screen.dart';
import 'screens/user_shell.dart';
import 'services/auth_service.dart';
import 'services/car_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_logo.dart';

enum AppDestination { login, userHome, adminHome }

class SplashScreen extends StatefulWidget {
  final void Function(AppDestination destination) onReady;

  const SplashScreen({super.key, required this.onReady});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await AuthService.instance.loadStoredSession();
    var loggedIn = AuthService.instance.isLoggedIn;

    if (loggedIn) {
      loggedIn = await AuthService.instance.validateSession();
    }

    if (loggedIn) {
      await CarService.instance.load();
    }

    if (!mounted) return;

    if (!loggedIn) {
      widget.onReady(AppDestination.login);
      return;
    }

    final isAdmin = AuthService.instance.currentUser?.isAdmin ?? false;
    widget.onReady(isAdmin ? AppDestination.adminHome : AppDestination.userHome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogo(showTagline: true),
            const SizedBox(height: 48),
            const SizedBox(
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
  AppDestination? _destination;

  @override
  void initState() {
    super.initState();
    AuthService.instance.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged(bool loggedIn) {
    if (!loggedIn && mounted && _destination != null && _destination != AppDestination.login) {
      setState(() => _destination = AppDestination.login);
    }
  }

  void _onSplashReady(AppDestination destination) {
    setState(() => _destination = destination);
  }

  void _onAuthSuccess() async {
    await CarService.instance.load();
    final isAdmin = AuthService.instance.currentUser?.isAdmin ?? false;
    setState(() => _destination = isAdmin ? AppDestination.adminHome : AppDestination.userHome);
  }

  void _onLogout() {
    setState(() => _destination = AppDestination.login);
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    switch (_destination) {
      case null:
        home = SplashScreen(onReady: _onSplashReady);
      case AppDestination.login:
        home = LoginScreen(onLoggedIn: _onAuthSuccess);
      case AppDestination.userHome:
        home = UserShell(onLogout: _onLogout);
      case AppDestination.adminHome:
        home = AdminShell(onLogout: _onLogout);
    }

    return MaterialApp(
      title: 'RenderWheels',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: home,
    );
  }
}
