import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_theme_builder.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/settings_repository.dart';
import '../utils/money_format.dart';
import '../widgets/design_system/app_button.dart';
import '../widgets/design_system/app_card.dart';
import '../widgets/design_system/logout_confirm_dialog.dart';
import '../widgets/design_system/summary_panel.dart';
import '../widgets/design_system/theme_language_switcher.dart';
import 'beginner_guide_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AppSettingsController settings;
  final VoidCallback onLogout;
  final VoidCallback? onUserUpdated;

  const ProfileScreen({
    super.key,
    required this.settings,
    required this.onLogout,
    this.onUserUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double? _generationPrice;
  bool _loading = true;
  String? _avatarPath;
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await AuthRepository.instance.refreshCurrentUser();
      _generationPrice = await SettingsRepository.instance.getGenerationPrice();
      final user = AuthRepository.instance.currentUser;
      if (user != null) {
        final override = await ProfileRepository.instance.getProfileOverride(user.id);
        _avatarPath = override?['avatar_path'];
        _displayName = override?['display_name'] ?? user.displayName;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
      widget.onUserUpdated?.call();
    }
  }

  Future<void> _openEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(onSaved: _load)),
    );
    _load();
  }

  Future<void> _logout() async {
    final confirmed = await showLogoutConfirmDialog(context);
    if (confirmed != true || !mounted) return;

    await AuthRepository.instance.logout();
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;
    final user = AuthRepository.instance.currentUser;
    final name = _displayName ?? user?.displayName ?? '';
    final created = user?.createdAt;

    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PremiumTopBar(
                settings: widget.settings,
                trailing: IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loading ? null : _load,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.screenPaddingH),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    s.profile,
                    style: tokens.textStyle(fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.6),
                  ),
                  const SizedBox(height: DesignTokens.spacing24),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: tokens.primaryGradient,
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: tokens.surfaceMuted,
                        backgroundImage: _avatarPath != null && File(_avatarPath!).existsSync()
                            ? FileImage(File(_avatarPath!))
                            : null,
                        child: _avatarPath == null || !File(_avatarPath!).existsSync()
                            ? Text(
                                (name.isNotEmpty ? name[0] : '?').toUpperCase(),
                                style: tokens.textStyle(fontSize: 32, fontWeight: FontWeight.w700),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing16),
                  Center(
                    child: Text(
                      name,
                      style: tokens.textStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Center(
                    child: Text(
                      user?.email ?? '',
                      style: tokens.textStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ),
                  if (created != null) ...[
                    const SizedBox(height: DesignTokens.spacing8),
                    Center(
                      child: Text(
                        DateFormat.yMMMd().format(created.toLocal()),
                        style: tokens.textStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: tokens.textTertiary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: DesignTokens.spacing32),
                  Text(
                    s.settings,
                    style: tokens.textStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: DesignTokens.spacing12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.appearance,
                          style: tokens.textStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacing12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(s.theme, style: tokens.textStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                            ),
                            Text(
                              s.themeLight,
                              style: tokens.textStyle(fontSize: 14, fontWeight: FontWeight.w500, color: tokens.textSecondary),
                            ),
                          ],
                        ),
                        const Divider(height: DesignTokens.spacing32),
                        Row(
                          children: [
                            Expanded(
                              child: Text(s.language, style: tokens.textStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                            ),
                            LanguageSwitcher(controller: widget.settings),
                          ],
                        ),
                        const Divider(height: DesignTokens.spacing32),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.menu_book_outlined, color: tokens.accent),
                          title: Text(s.guideReplay, style: tokens.textStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                          trailing: Icon(Icons.chevron_right_rounded, color: tokens.textTertiary),
                          onTap: () => BeginnerGuideScreen.open(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing16),
                  SummaryPanel(
                    title: s.estimatedPrice,
                    rows: [
                      SummaryRow(
                        label: 'Balance',
                        value: _loading ? '…' : MoneyFormat.usd(user?.balance ?? 0),
                      ),
                      SummaryRow(
                        label: s.estimatedPrice,
                        value: _loading ? '…' : MoneyFormat.pricePerGeneration(_generationPrice ?? 0.10),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacing16),
                  AppButton(
                    label: s.editProfile,
                    variant: AppButtonVariant.secondary,
                    icon: Icons.edit_outlined,
                    onPressed: _openEdit,
                  ),
                  const SizedBox(height: DesignTokens.spacing12),
                  AppButton(
                    label: s.logout,
                    variant: AppButtonVariant.ghost,
                    icon: Icons.logout_rounded,
                    onPressed: _logout,
                  ),
                  const SizedBox(height: DesignTokens.spacing32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
