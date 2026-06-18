import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_theme_builder.dart';
import '../core/theme/app_tokens.dart';
import 'my_cars_screen.dart';
import 'profile_screen.dart';
import 'welcome_screen.dart';

class UserShell extends StatefulWidget {
  final AppSettingsController settings;
  final VoidCallback onLogout;

  const UserShell({
    super.key,
    required this.settings,
    required this.onLogout,
  });

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _index = 0;

  void _onUserUpdated() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final tokens = context.tokens;

    final pages = <Widget>[
      WelcomeScreen(
        settings: widget.settings,
        onBalanceChanged: _onUserUpdated,
        onLogout: widget.onLogout,
      ),
      const MyCarsScreen(),
      ProfileScreen(
        settings: widget.settings,
        onLogout: widget.onLogout,
        onUserUpdated: _onUserUpdated,
      ),
    ];

    return Scaffold(
      backgroundColor: tokens.background,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border(top: BorderSide(color: tokens.border.withValues(alpha: 0.5))),
          boxShadow: [
            BoxShadow(
              color: tokens.shadow.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: s.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.directions_car_outlined),
              selectedIcon: const Icon(Icons.directions_car_rounded),
              label: s.navCars,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded),
              label: s.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}
