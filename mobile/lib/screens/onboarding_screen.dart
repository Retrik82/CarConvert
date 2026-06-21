import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_theme_builder.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/page_transitions.dart';
import '../widgets/app_logo.dart';
import '../widgets/design_system/app_button.dart';
import '../widgets/design_system/theme_language_switcher.dart';
import '../widgets/design_system/welcome_before_after_slider.dart';
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
                  LanguageSwitcher(
                    controller: settings,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.screenPaddingH,
                ),
                child: Column(
                  children: [
                    const AppLogo(iconSize: 56, titleSize: 30, useImageLogo: true),
                    const SizedBox(height: DesignTokens.spacing24),
                    const Expanded(
                      child: Center(
                        child: WelcomeBeforeAfterSlider(),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacing16),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(DesignTokens.radiusHero),
                ),
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.textDark.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  DesignTokens.screenPaddingH,
                  DesignTokens.spacing24,
                  DesignTokens.screenPaddingH,
                  bottomInset + DesignTokens.spacing24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GradientHighlightText(
                      text: s.welcomeTitle,
                      highlight: appName,
                      baseStyle: tokens.textStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
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
                    const SizedBox(height: DesignTokens.spacing24),
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
            ),
          ],
        ),
      ),
    );
  }
}
