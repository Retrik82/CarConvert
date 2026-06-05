import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'capture_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback? onBalanceChanged;

  const WelcomeScreen({super.key, this.onBalanceChanged});

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
    final user = AuthService.instance.currentUser;
    final name = user?.displayName ?? 'there';

    return Scaffold(
      backgroundColor: AppTheme.background,
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
