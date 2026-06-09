import 'package:flutter/material.dart';

import '../repositories/auth_repository.dart';
import '../theme/app_theme.dart';
import 'capture_screen.dart';

Future<void> _confirmLogout(BuildContext context, VoidCallback onLogout) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Выйти из аккаунта?'),
      content: const Text('Вы сможете войти снова в любое время.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
          child: const Text('Выйти'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  await AuthRepository.instance.logout();
  onLogout();
}

class WelcomeScreen extends StatelessWidget {
  final VoidCallback? onBalanceChanged;
  final VoidCallback? onLogout;

  const WelcomeScreen({super.key, this.onBalanceChanged, this.onLogout});

  void _openCapture(BuildContext context, CaptureMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaptureScreen(
          initialMode: mode,
          onBalanceChanged: onBalanceChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthRepository.instance.currentUser;
    final name = user?.displayName ?? 'there';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: onLogout != null
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.account_circle_outlined),
                  onSelected: (value) {
                    if (value == 'logout' && onLogout != null) {
                      _confirmLogout(context, onLogout!);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: AppTheme.error, size: 20),
                          const SizedBox(width: 12),
                          Text('Выйти', style: TextStyle(color: AppTheme.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingScreenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Text(
                'Hello, $name',
                style: AppTheme.textStyle(fontSize: 32, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'How would you like to start?',
                style: AppTheme.textStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _openCapture(context, CaptureMode.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Take Photo'),
              ),
              const SizedBox(height: AppTheme.spacingElement),
              OutlinedButton.icon(
                onPressed: () => _openCapture(context, CaptureMode.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('From Gallery'),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
