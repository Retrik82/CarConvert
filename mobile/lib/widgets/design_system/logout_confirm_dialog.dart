import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/design_tokens.dart';
import 'app_button.dart';

Future<bool?> showLogoutConfirmDialog(BuildContext context) {
  final s = context.strings;
  final tokens = context.tokens;

  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing24),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: tokens.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded, color: tokens.error, size: 28),
            ),
            const SizedBox(height: DesignTokens.spacing16),
            Text(
              s.logoutConfirmTitle,
              textAlign: TextAlign.center,
              style: tokens.textStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DesignTokens.spacing8),
            Text(
              s.logoutConfirmBody,
              textAlign: TextAlign.center,
              style: tokens.textStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: DesignTokens.spacing24),
            AppButton(
              label: s.logout,
              icon: Icons.logout_rounded,
              onPressed: () => Navigator.pop(ctx, true),
            ),
            const SizedBox(height: DesignTokens.spacing12),
            AppButton(
              label: s.cancel,
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.pop(ctx, false),
            ),
          ],
        ),
      ),
    ),
  );
}
