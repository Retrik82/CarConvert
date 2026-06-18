import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_theme_builder.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../widgets/app_logo.dart';
import '../core/theme/page_transitions.dart';
import '../widgets/design_system/app_button.dart';
import '../widgets/design_system/hero_before_after.dart';
import '../widgets/design_system/theme_language_switcher.dart';
import 'forgot_password_screen.dart';
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

  void _pushAuthScreen(BuildContext context, Widget screen) {
    Navigator.push(context, AppPageTransitions.fadeSlide(page: screen));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;
    final appName = s.appName;

    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        child: Column(
          children: [
            PremiumTopBar(settings: settings),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.screenPaddingH),
                child: Column(
                  children: [
                    const AppLogo(iconSize: 44, titleSize: 26),
                    const SizedBox(height: DesignTokens.spacing24),
                    HeroBeforeAfter(
                      height: MediaQuery.sizeOf(context).height * 0.32,
                    ),
                    const SizedBox(height: DesignTokens.spacing32),
                    GradientHighlightText(
                      text: s.welcomeTitle,
                      highlight: appName,
                      baseStyle: tokens.textStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacing8),
                    Text(
                      s.welcomeSubtitle,
                      textAlign: TextAlign.center,
                      style: tokens.textStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacing24),
                    FeatureHighlightRow(
                      features: [
                        FeatureHighlight(
                          icon: Icons.auto_fix_high_rounded,
                          title: s.takePhoto.split(' ').first,
                          subtitle: s.startCapture,
                        ),
                        FeatureHighlight(
                          icon: Icons.crop_square_rounded,
                          title: s.chooseBackground.split(' ').first,
                          subtitle: s.backgroundSelected,
                        ),
                        FeatureHighlight(
                          icon: Icons.bolt_rounded,
                          title: s.fromGallery.split(' ').first,
                          subtitle: s.dashboardSubtitle.split('.').first,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.screenPaddingH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    label: s.login,
                    icon: Icons.mail_outline_rounded,
                    onPressed: () => _pushAuthScreen(
                      context,
                      LoginScreen(onLoggedIn: onLoggedIn),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing12),
                  AppButton(
                    label: s.register,
                    variant: AppButtonVariant.secondary,
                    icon: Icons.person_add_outlined,
                    onPressed: () => _pushAuthScreen(
                      context,
                      RegisterScreen(onRegistered: onLoggedIn),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing16),
                  Center(
                    child: TextButton(
                      onPressed: () => _pushAuthScreen(
                        context,
                        const ForgotPasswordScreen(),
                      ),
                      child: Text(
                        s.forgotPassword,
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
