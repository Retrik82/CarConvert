import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'pricing_screen.dart';

class AdminShell extends StatelessWidget {
  final VoidCallback onLogout;

  const AdminShell({super.key, required this.onLogout});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Вы сможете войти снова в любое время.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

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
