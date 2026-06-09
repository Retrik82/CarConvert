import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/prefs_service.dart';
import '../theme/app_theme.dart';
import '../utils/money_format.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback? onUserUpdated;

  const ProfileScreen({super.key, required this.onLogout, this.onUserUpdated});

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
      await AuthService.instance.refreshCurrentUser();
      _generationPrice = await ApiService.instance.getGenerationPrice();
      final user = AuthService.instance.currentUser;
      if (user != null) {
        final override = await PrefsService.getProfileOverride(user.id);
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
    if (confirmed != true || !mounted) return;

    await AuthService.instance.logout();
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final name = _displayName ?? user?.displayName ?? '';
    final created = user?.createdAt;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(onPressed: _openEdit, icon: const Icon(Icons.edit_outlined)),
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingScreenH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppTheme.surfaceMuted,
                backgroundImage: _avatarPath != null && File(_avatarPath!).existsSync()
                    ? FileImage(File(_avatarPath!))
                    : null,
                child: _avatarPath == null || !File(_avatarPath!).existsSync()
                    ? Text(
                        (name.isNotEmpty ? name[0] : '?').toUpperCase(),
                        style: AppTheme.textStyle(fontSize: 32, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppTheme.spacingElement),
            Center(
              child: Text(
                name,
                style: AppTheme.textStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
            ),
            Center(
              child: Text(
                user?.email ?? '',
                style: AppTheme.textStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppTheme.textSecondary),
              ),
            ),
            if (created != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Member since ${DateFormat('MMM d, yyyy').format(created.toLocal())}',
                  style: AppTheme.textStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppTheme.textTertiary),
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spacingSection),
            _infoCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Balance',
              value: _loading ? '...' : MoneyFormat.usd(user?.balance ?? 0),
            ),
            const SizedBox(height: AppTheme.spacingElement),
            _infoCard(
              icon: Icons.monetization_on_outlined,
              title: 'Render price',
              value: _loading ? '...' : MoneyFormat.pricePerGeneration(_generationPrice ?? 0.10),
            ),
            const SizedBox(height: AppTheme.spacingElement),
            _paymentPlaceholder(),
            const SizedBox(height: AppTheme.spacingSection),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error),
                ),
                child: const Text('Выйти из аккаунта'),
              ),
            ),
            const SizedBox(height: AppTheme.spacingElement),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({required IconData icon, required String title, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingElement),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textPrimary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.textStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTheme.textStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingElement),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment_outlined, color: AppTheme.textPrimary, size: 22),
              const SizedBox(width: 14),
              Text(
                'Payment method',
                style: AppTheme.textStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Coming soon',
            style: AppTheme.textStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Top-up and card payments will be available in a future update.',
            style: AppTheme.textStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }
}
