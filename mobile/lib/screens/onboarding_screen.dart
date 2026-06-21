import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_theme_builder.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/page_transitions.dart';
import '../widgets/app_logo.dart';
import '../widgets/design_system/app_button.dart';
import '../widgets/design_system/auth_welcome_hero_banner.dart';
import '../widgets/design_system/theme_language_switcher.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class OnboardingScreen extends StatelessWidget {
  final AppSettingsController settings;
  final VoidCallback onLoggedIn;

  const OnboardingScreen({
    super.key,
    required this.settings,
    required this.onLoggedIn,
  });

  void _openLogin(BuildContext context) {
    Navigator.push(
      context,
      AppPageTransitions.fadeSlide(
        page: LoginScreen(onLoggedIn: onLoggedIn),
      ),
    );
  }

  void _openRegister(BuildContext context) {
    Navigator.push(
      context,
      AppPageTransitions.fadeSlide(
        page: RegisterScreen(onRegistered: onLoggedIn),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;
    final appName = s.appName;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.screenPaddingH,
                vertical: DesignTokens.spacing8,
              ),
              child: Row(
                children: [
                  const Spacer(),
                  LanguageSwitcher(controller: settings),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: DesignTokens.screenPaddingH),
              child: AppLogo(iconSize: 52, titleSize: 28, useImageLogo: true),
            ),
            const AuthWelcomeHeroBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.screenPaddingH,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: DesignTokens.spacing16),
                    GradientHighlightText(
                      text: s.welcomeTitle,
                      highlight: appName,
                      baseStyle: tokens.textStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacing12),
                    Text(
                      s.welcomeSubtitle,
                      textAlign: TextAlign.center,
                      style: tokens.textStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: tokens.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.screenPaddingH,
                DesignTokens.spacing8,
                DesignTokens.screenPaddingH,
                bottomInset + DesignTokens.spacing16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    label: s.login,
                    icon: Icons.login_rounded,
                    onPressed: () => _openLogin(context),
                  ),
                  const SizedBox(height: DesignTokens.spacing12),
                  AppButton(
                    label: s.register,
                    variant: AppButtonVariant.secondary,
                    icon: Icons.person_add_outlined,
                    onPressed: () => _openRegister(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
