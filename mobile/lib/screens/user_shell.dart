import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'capture_screen.dart';
import 'my_cars_screen.dart';
import 'profile_screen.dart';

class UserShell extends StatefulWidget {
  final VoidCallback onLogout;

  const UserShell({super.key, required this.onLogout});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _index = 0;

  void _onUserUpdated() => setState(() {});

  void _goToCapture() => setState(() => _index = 0);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      CaptureScreen(isActive: _index == 0, onBalanceChanged: _onUserUpdated),
      MyCarsScreen(onCapture: _goToCapture),
      ProfileScreen(onLogout: widget.onLogout, onUserUpdated: _onUserUpdated),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.camera_alt_outlined), selectedIcon: Icon(Icons.camera_alt), label: 'Capture'),
          NavigationDestination(icon: Icon(Icons.directions_car_outlined), selectedIcon: Icon(Icons.directions_car), label: 'My Cars'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
