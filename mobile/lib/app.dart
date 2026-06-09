import 'package:flutter/material.dart';

import 'screens/admin_shell.dart';
import 'screens/login_screen.dart';
import 'screens/user_shell.dart';
import 'services/auth_service.dart';
import 'services/car_service.dart';
import 'theme/app_theme.dart';
import 'utils/debug_log.dart';
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
    // #region agent log
    final sw = Stopwatch()..start();
    DebugLog.emit('app.dart:_bootstrap', 'splash bootstrap start', hypothesisId: 'C');
    // #endregion
    await AuthService.instance.loadStoredSession();
    // #region agent log
    DebugLog.emit('app.dart:_bootstrap', 'loadStoredSession done', hypothesisId: 'C', data: {'ms': sw.elapsedMilliseconds});
    // #endregion
    var loggedIn = AuthService.instance.isLoggedIn;

    if (loggedIn) {
      loggedIn = await AuthService.instance.validateSession();
      // #region agent log
      DebugLog.emit('app.dart:_bootstrap', 'validateSession done', hypothesisId: 'C', data: {'ms': sw.elapsedMilliseconds, 'loggedIn': loggedIn});
      // #endregion
    }

    if (loggedIn) {
      await CarService.instance.load();
      // #region agent log
      DebugLog.emit('app.dart:_bootstrap', 'carService.load done', hypothesisId: 'C', data: {'ms': sw.elapsedMilliseconds});
      // #endregion
    }

    if (!mounted) return;

    if (!loggedIn) {
      // #region agent log
      DebugLog.emit('app.dart:_bootstrap', 'navigate to login', hypothesisId: 'C', data: {'ms': sw.elapsedMilliseconds});
      // #endregion
      widget.onReady(AppDestination.login);
      return;
    }

    final isAdmin = AuthService.instance.currentUser?.isAdmin ?? false;
    // #region agent log
    DebugLog.emit('app.dart:_bootstrap', 'navigate to home', hypothesisId: 'C', data: {'ms': sw.elapsedMilliseconds, 'isAdmin': isAdmin});
    // #endregion
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
      _handleLoggedOut();
    }
  }

  void _onSplashReady(AppDestination destination) {
    setState(() => _destination = destination);
  }

  Future<void> _onAuthSuccess() async {
    // #region agent log
    final sw = Stopwatch()..start();
    DebugLog.emit('app.dart:_onAuthSuccess', 'auth success callback start', hypothesisId: 'B', data: {'destination': _destination?.name});
    // #endregion
    await CarService.instance.load();
    // #region agent log
    DebugLog.emit('app.dart:_onAuthSuccess', 'carService.load done before setState', hypothesisId: 'B', data: {'ms': sw.elapsedMilliseconds, 'mounted': mounted});
    // #endregion
    if (!mounted) return;
    final isAdmin = AuthService.instance.currentUser?.isAdmin ?? false;
    final next = isAdmin ? AppDestination.adminHome : AppDestination.userHome;
    setState(() => _destination = next);
    // #region agent log
    DebugLog.emit('app.dart:_onAuthSuccess', 'setState destination updated', hypothesisId: 'A', data: {'ms': sw.elapsedMilliseconds, 'next': next.name});
    // #endregion
  }

  Future<void> _handleLoggedOut() async {
    await CarService.instance.clear();
    if (mounted) setState(() => _destination = AppDestination.login);
  }

  void _onLogout() {
    _handleLoggedOut();
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
