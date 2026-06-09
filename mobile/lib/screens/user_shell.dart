import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/debug_log.dart';
import 'my_cars_screen.dart';
import 'profile_screen.dart';
import 'welcome_screen.dart';

class UserShell extends StatefulWidget {
  final VoidCallback onLogout;

  const UserShell({super.key, required this.onLogout});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // #region agent log
    DebugLog.emit('user_shell.dart:initState', 'UserShell mounted (welcome should be visible)', hypothesisId: 'A');
    // #endregion
  }

  void _onUserUpdated() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      WelcomeScreen(onBalanceChanged: _onUserUpdated, onLogout: widget.onLogout),
      const MyCarsScreen(),
      ProfileScreen(onLogout: widget.onLogout, onUserUpdated: _onUserUpdated),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.directions_car_outlined), selectedIcon: Icon(Icons.directions_car), label: 'My Cars'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
