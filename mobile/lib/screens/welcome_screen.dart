import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_theme_builder.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/page_transitions.dart';
import '../repositories/auth_repository.dart';
import '../repositories/background_repository.dart';
import '../widgets/design_system/app_card.dart';
import '../widgets/design_system/logout_confirm_dialog.dart';
import '../widgets/design_system/theme_language_switcher.dart';
import '../widgets/design_system/welcome_before_after_slider.dart';
import 'backgrounds_screen.dart';
import 'capture_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final AppSettingsController settings;
  final VoidCallback? onBalanceChanged;
  final VoidCallback? onLogout;

  const WelcomeScreen({
    super.key,
    required this.settings,
    this.onBalanceChanged,
    this.onLogout,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await BackgroundRepository.instance.loadSavedSelection();
      if (mounted) setState(() {});
    });
  }

  Future<void> _confirmLogout() async {
    if (widget.onLogout == null) return;
    final confirmed = await showLogoutConfirmDialog(context);
    if (confirmed != true || !mounted) return;
    await AuthRepository.instance.logout();
    widget.onLogout!();
  }

  void _openCapture(BuildContext context, CaptureMode mode) {
    Navigator.push(
      context,
      AppPageTransitions.fadeSlide(
        page: CaptureScreen(
          initialMode: mode,
          onBalanceChanged: widget.onBalanceChanged,
        ),
      ),
    );
  }

  void _openBackgrounds(BuildContext context) {
    Navigator.push(
      context,
      AppPageTransitions.fadeSlide(page: const BackgroundsScreen()),
    ).then((_) => setState(() {}));
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
              settings: widget.settings,
              trailing: widget.onLogout != null
                  ? IconButton(
                      icon: const Icon(Icons.more_horiz_rounded),
                      onPressed: _showAccountMenu,
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
                            style: tokens.textStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.6),
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
                          const WelcomeBeforeAfterSlider(),
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
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: tokens.primaryGradient,
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
                                  ),
                                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                                ),
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
                                        selectedBackground.displayName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: tokens.textStyle(fontSize: 15, fontWeight: FontWeight.w600),
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

  void _showAccountMenu() {
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
                _confirmLogout();
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
      padding: const EdgeInsets.all(DesignTokens.spacing24),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: highlighted ? tokens.primaryGradient : null,
              color: highlighted ? null : tokens.accentMuted,
              borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
            ),
            child: Icon(
              icon,
              color: highlighted ? tokens.onAccent : tokens.accent,
              size: 24,
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
                const SizedBox(height: 4),
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
