import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_theme_builder.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../repositories/auth_repository.dart';
import '../repositories/background_repository.dart';
import '../widgets/design_system/app_card.dart';
import '../widgets/design_system/car_hero.dart';
import '../widgets/design_system/theme_language_switcher.dart';
import 'backgrounds_screen.dart';
import 'capture_screen.dart';

Future<void> _confirmLogout(BuildContext context, VoidCallback onLogout) async {
  final s = context.strings;
  final tokens = context.tokens;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.logoutConfirmTitle),
      content: Text(s.logoutConfirmBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: tokens.error),
          child: Text(s.logout),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  await AuthRepository.instance.logout();
  onLogout();
}

class WelcomeScreen extends StatelessWidget {
  final AppSettingsController settings;
  final VoidCallback? onBalanceChanged;
  final VoidCallback? onLogout;

  const WelcomeScreen({
    super.key,
    required this.settings,
    this.onBalanceChanged,
    this.onLogout,
  });

  void _openCapture(BuildContext context, CaptureMode mode) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => CaptureScreen(
          initialMode: mode,
          onBalanceChanged: onBalanceChanged,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _openBackgrounds(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BackgroundsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;
    final user = AuthRepository.instance.currentUser;
    final name = user?.displayName ?? 'there';
    final selectedBackground = BackgroundRepository.instance.selected;

    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        child: Column(
          children: [
            PremiumTopBar(
              settings: settings,
              trailing: onLogout != null
                  ? IconButton(
                      icon: const Icon(Icons.more_horiz_rounded),
                      onPressed: () => _showAccountMenu(context),
                    )
                  : null,
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.screenPaddingH),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.greeting(name),
                            style: tokens.textStyle(fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.6),
                          ),
                          const SizedBox(height: DesignTokens.spacing8),
                          Text(
                            s.dashboardSubtitle,
                            style: tokens.textStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: tokens.textSecondary,
                            ),
                          ),
                          const SizedBox(height: DesignTokens.spacing24),
                          AnimatedSwitcher(
                            duration: DesignTokens.durationTheme,
                            child: CarHero(
                              key: ValueKey(tokens.isDark),
                              height: 200,
                            ),
                          ),
                          const SizedBox(height: DesignTokens.spacing24),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.screenPaddingH),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (selectedBackground != null)
                          AppCard(
                            padding: const EdgeInsets.all(DesignTokens.spacing16),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: tokens.success, size: 22),
                                const SizedBox(width: DesignTokens.spacing12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.backgroundSelected,
                                        style: tokens.textStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: tokens.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        '${selectedBackground.displayName} · ${selectedBackground.variant.angleLabel}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: tokens.textStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        _ActionCard(
                          icon: Icons.wallpaper_outlined,
                          title: selectedBackground == null ? s.chooseBackground : s.changeBackground,
                          subtitle: s.backgroundsIntro.split('.').first,
                          onTap: () => _openBackgrounds(context),
                          highlighted: selectedBackground == null,
                        ),
                        const SizedBox(height: DesignTokens.spacing12),
                        _ActionCard(
                          icon: Icons.camera_alt_outlined,
                          title: s.takePhoto,
                          subtitle: s.startCapture,
                          onTap: () => _openCapture(context, CaptureMode.camera),
                          highlighted: true,
                        ),
                        const SizedBox(height: DesignTokens.spacing12),
                        _ActionCard(
                          icon: Icons.photo_library_outlined,
                          title: s.fromGallery,
                          subtitle: s.startCapture,
                          onTap: () => _openCapture(context, CaptureMode.gallery),
                        ),
                        const SizedBox(height: DesignTokens.spacing32),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountMenu(BuildContext context) {
    final s = context.strings;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: Text(s.logout),
              onTap: () {
                Navigator.pop(ctx);
                if (onLogout != null) _confirmLogout(context, onLogout!);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlighted;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return AppCard(
      onTap: onTap,
      elevated: highlighted,
      padding: const EdgeInsets.all(DesignTokens.spacing16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: highlighted ? tokens.accent : tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
            ),
            child: Icon(
              icon,
              color: highlighted ? tokens.onAccent : tokens.textPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: DesignTokens.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tokens.textStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tokens.textStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: tokens.textTertiary),
        ],
      ),
    );
  }
}