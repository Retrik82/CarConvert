import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/prefs_service.dart';

class CarConvertApp extends StatefulWidget {
  const CarConvertApp({super.key});

  @override
  State<CarConvertApp> createState() => _CarConvertAppState();
}

class _CarConvertAppState extends State<CarConvertApp> {
  bool _loading = true;
  bool _loggedIn = false;
  bool _onboardingDone = false;

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
    final onboarding = await PrefsService.isOnboardingDone();
    setState(() {
      _loggedIn = loggedIn;
      _onboardingDone = onboarding;
      _loading = false;
    });
  }

  void _onAuthSuccess() {
    setState(() => _loggedIn = true);
  }

  void _onOnboardingComplete() {
    setState(() => _onboardingDone = true);
  }

  void _onLogout() {
    setState(() {
      _loggedIn = false;
      _onboardingDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (_loading) {
      home = const Scaffold(
        backgroundColor: Color(0xFF0D1117),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    } else if (!_loggedIn) {
      home = LoginScreen(onLoggedIn: _onAuthSuccess);
    } else if (!_onboardingDone) {
      home = OnboardingScreen(onComplete: _onOnboardingComplete);
    } else {
      home = HomeShell(onLogout: _onLogout);
    }

    return MaterialApp(
      title: 'CarConvert',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: home,
    );
  }
}
