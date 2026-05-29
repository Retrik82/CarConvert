import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'admin_panel_screen.dart';
import 'camera_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  final VoidCallback onLogout;

  const HomeShell({super.key, required this.onLogout});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _onUserUpdated() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthService.instance.currentUser?.isAdmin ?? false;
    final pages = <Widget>[
      if (isAdmin) const AdminPanelScreen(),
      CameraScreen(onBalanceChanged: _onUserUpdated),
      const HistoryScreen(),
      ProfileScreen(onLogout: widget.onLogout, onUserUpdated: _onUserUpdated),
    ];

    final destinations = <NavigationDestination>[
      if (isAdmin)
        const NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: 'Админ'),
      const NavigationDestination(icon: Icon(Icons.camera_alt), label: 'Камера'),
      const NavigationDestination(icon: Icon(Icons.history), label: 'История'),
      const NavigationDestination(icon: Icon(Icons.person), label: 'Профиль'),
    ];

    if (_index >= pages.length) {
      _index = 0;
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: const Color(0xFF161B22),
        indicatorColor: Colors.amber.withValues(alpha: 0.2),
        destinations: destinations,
      ),
    );
  }
}
