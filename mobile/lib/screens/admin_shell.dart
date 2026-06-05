import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'pricing_screen.dart';

class AdminShell extends StatelessWidget {
  final VoidCallback onLogout;

  const AdminShell({super.key, required this.onLogout});

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.logout();
    if (context.mounted) onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return PricingScreen(
      onLogout: () => _logout(context),
    );
  }
}
