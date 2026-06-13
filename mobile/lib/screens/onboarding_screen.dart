import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_theme_builder.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../widgets/design_system/app_button.dart';
import '../widgets/design_system/car_hero.dart';
import '../widgets/design_system/theme_language_switcher.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  final AppSettingsController settings;
  final VoidCallback onLoggedIn;

  const OnboardingScreen({
    super.key,
    required this.settings,
    required this.onLoggedIn,
  });

  void _openEmailLogin(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LoginScreen(onLoggedIn: onLoggedIn),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: DesignTokens.curveEmphasized),
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(animation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;

    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        child: Column(
          children: [
            PremiumTopBar(settings: settings),
            Expanded(
              child: AnimatedSwitcher(
                duration: DesignTokens.durationTheme,
                child: CarHero(
                  key: ValueKey(tokens.isDark),
                  height: MediaQuery.sizeOf(context).height * 0.38,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.screenPaddingH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.welcomeTitle,
                    style: tokens.textStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: DesignTokens.spacing8),
                  Text(
                    s.welcomeSubtitle,
                    style: tokens.textStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing32),
                  AppButton(
                    label: s.continueWithEmail,
                    icon: Icons.mail_outline_rounded,
                    onPressed: () => _openEmailLogin(context),
                  ),
                  const SizedBox(height: DesignTokens.spacing12),
                  AppButton(
                    label: s.continueWithToken,
                    icon: Icons.qr_code_2_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _openEmailLogin(context),
                  ),
                  const SizedBox(height: DesignTokens.spacing16),
                  Center(
                    child: TextButton(
                      onPressed: () => _openEmailLogin(context),
                      child: Text(
                        s.companyLogin,
                        style: tokens.textStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.paddingOf(context).bottom + DesignTokens.spacing16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
