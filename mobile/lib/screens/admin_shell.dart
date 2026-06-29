import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../repositories/auth_repository.dart';
import 'pricing_screen.dart';

class AdminShell extends StatelessWidget {
  final VoidCallback onLogout;

  const AdminShell({super.key, required this.onLogout});

  Future<void> _logout(BuildContext context) async {
    final strings = context.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.logoutConfirmTitle),
        content: Text(strings.logoutConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(strings.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.logout),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await AuthRepository.instance.logout();
    if (context.mounted) onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return PricingScreen(
      onLogout: () => _logout(context),
    );
  }
}
