import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../models/background.dart';
import '../repositories/auth_repository.dart';
import '../repositories/background_repository.dart';
import '../utils/error_utils.dart';
import '../utils/money_format.dart';
import '../widgets/background_scene_preview.dart';
import '../widgets/design_system/app_button.dart';
import '../widgets/design_system/app_card.dart';
import '../widgets/design_system/state_views.dart';
import '../widgets/form_fields.dart';

class BackgroundsScreen extends StatefulWidget {
  final VoidCallback? onSelected;

  const BackgroundsScreen({super.key, this.onSelected});

  @override
  State<BackgroundsScreen> createState() => _BackgroundsScreenState();
}

class _BackgroundsScreenState extends State<BackgroundsScreen> {
  final _repo = BackgroundRepository.instance;
  BackgroundCatalog? _catalog;
  String _selectedAngle = 'three_quarter_left';
  bool _loading = true;
  bool _creating = false;
  String? _error;

  static const _angles = [
    ('three_quarter_left', '3/4 L'),
    ('three_quarter_right', '3/4 R'),
    ('left', 'Left'),
    ('right', 'Right'),
    ('front', 'Front'),
    ('rear', 'Rear'),
    ('interior', 'Inside'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    _repo.clearImageCache();
    try {
      final catalog = await _repo.fetchCatalog();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        if (_repo.selected == null && catalog.presets.isNotEmpty) {
          final preset = catalog.presets.first;
          final variant = preset.defaultVariant;
          if (variant != null) _repo.select(preset, variant);
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = userFacingError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectPreset(BackgroundPreset preset) {
    final variant = preset.variantByAngle(_selectedAngle) ?? preset.defaultVariant;
    if (variant == null) return;
    _repo.select(preset, variant);
    widget.onSelected?.call();
    if (mounted) Navigator.pop(context, _repo.selected);
  }

  Future<void> _showCreateSheet() async {
    final catalog = _catalog;
    if (catalog == null) return;
    final s = context.strings;
    final tokens = context.tokens;

    final nameController = TextEditingController();
    final promptController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: DesignTokens.screenPaddingH,
            right: DesignTokens.screenPaddingH,
            top: DesignTokens.spacing24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + DesignTokens.spacing24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s.createCustomBackground, style: tokens.textStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: DesignTokens.spacing8),
                Text(
                  '${s.customBackgroundPrice} ${MoneyFormat.usd(catalog.customBackgroundPriceUsd)}',
                  style: tokens.textStyle(fontSize: 14, fontWeight: FontWeight.w400, color: tokens.textSecondary),
                ),
                const SizedBox(height: DesignTokens.spacing16),
                TextFormField(
                  controller: nameController,
                  decoration: appInputDecoration(s.backgroundName, hint: s.backgroundNameHint),
                  validator: (v) => v == null || v.trim().isEmpty ? s.fieldRequired : null,
                ),
                const SizedBox(height: DesignTokens.spacing12),
                TextFormField(
                  controller: promptController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: appInputDecoration(s.backgroundPrompt, hint: s.backgroundPromptHint),
                  validator: (v) => v == null || v.trim().length < 10 ? s.promptMinLength : null,
                ),
                const SizedBox(height: DesignTokens.spacing16),
                AppButton(
                  label: '${s.generate} ${MoneyFormat.usd(catalog.customBackgroundPriceUsd)}',
                  loading: _creating,
                  onPressed: _creating
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(ctx);
                          await _createCustom(nameController.text.trim(), promptController.text.trim());
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createCustom(String name, String prompt) async {
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      await AuthRepository.instance.refreshCurrentUser();
      final user = AuthRepository.instance.currentUser;
      final price = _catalog?.customBackgroundPriceUsd ?? 0.5;
      if (user != null && user.balance < price) {
        throw Exception(
          'Insufficient balance. Need ${MoneyFormat.usd(price)}, available ${MoneyFormat.usd(user.balance)}',
        );
      }
      final preset = await _repo.createCustomBackground(name: name, prompt: prompt);
      _repo.clearImageCache();
      await AuthRepository.instance.refreshCurrentUser();
      await _load();
      if (!mounted) return;
      _selectPreset(preset);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFacingError(e))));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;
    final selected = _repo.selected;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Text(s.backgroundsTitle),
        actions: [
          TextButton.icon(
            onPressed: _creating ? null : _showCreateSheet,
            icon: const Icon(Icons.auto_awesome_outlined, size: 18),
            label: Text(s.customBackground),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: tokens.accent))
          : _error != null
              ? ErrorStateView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(DesignTokens.screenPaddingH),
                    children: [
                      Text(
                        s.backgroundsIntro,
                        style: tokens.textStyle(fontSize: 15, fontWeight: FontWeight.w400, color: tokens.textSecondary),
                      ),
                      const SizedBox(height: DesignTokens.spacing16),
                      _AngleSelector(
                        angles: _angles,
                        selectedAngle: _selectedAngle,
                        onChanged: (a) => setState(() => _selectedAngle = a),
                      ),
                      if (selected != null) ...[
                        const SizedBox(height: DesignTokens.spacing16),
                        _SelectedBanner(selected: selected, angle: _selectedAngle),
                      ],
                      const SizedBox(height: DesignTokens.spacing24),
                      if (_catalog!.presets.isNotEmpty) ...[
                        Text(s.sharedBackgrounds, style: tokens.textStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: DesignTokens.spacing12),
                        ..._catalog!.presets.map(
                          (preset) => _BackgroundCard(
                            preset: preset,
                            selectedAngle: _selectedAngle,
                            isSelected: selected?.preset.id == preset.id && !preset.isCustom,
                            onSelect: () => _selectPreset(preset),
                          ),
                        ),
                      ],
                      if (_catalog!.custom.isNotEmpty) ...[
                        const SizedBox(height: DesignTokens.spacing24),
                        Text(s.yourBackgrounds, style: tokens.textStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: DesignTokens.spacing12),
                        ..._catalog!.custom.map(
                          (preset) => _BackgroundCard(
                            preset: preset,
                            selectedAngle: _selectedAngle,
                            isSelected: selected?.preset.id == preset.id,
                            onSelect: () => _selectPreset(preset),
                          ),
                        ),
                      ],
                      const SizedBox(height: DesignTokens.spacing32),
                    ],
                  ),
                ),
    );
  }
}

class _AngleSelector extends StatelessWidget {
  final List<(String, String)> angles;
  final String selectedAngle;
  final ValueChanged<String> onChanged;

  const _AngleSelector({
    required this.angles,
    required this.selectedAngle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: angles.length,
        separatorBuilder: (_, __) => const SizedBox(width: DesignTokens.spacing8),
        itemBuilder: (context, index) {
          final (angle, label) = angles[index];
          final selected = angle == selectedAngle;
          return FilterChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => onChanged(angle),
            selectedColor: tokens.accent,
            checkmarkColor: tokens.onAccent,
            labelStyle: tokens.textStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? tokens.onAccent : tokens.textPrimary,
            ),
            side: BorderSide(color: tokens.border),
            backgroundColor: tokens.surface,
          );
        },
      ),
    );
  }
}

class _SelectedBanner extends StatelessWidget {
  final SelectedBackground selected;
  final String angle;

  const _SelectedBanner({required this.selected, required this.angle});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;

    return AppCard(
      selected: true,
      padding: const EdgeInsets.all(DesignTokens.spacing12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
            child: SizedBox(
              width: 64,
              height: 64,
              child: BackgroundScenePreview(
                preset: selected.preset,
                angle: angle,
                borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.backgroundSelected}: ${selected.displayName}',
                  style: tokens.textStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  selected.variant.angleLabel,
                  style: tokens.textStyle(fontSize: 13, fontWeight: FontWeight.w400, color: tokens.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: tokens.success, size: 22),
        ],
      ),
    );
  }
}

class _BackgroundCard extends StatelessWidget {
  final BackgroundPreset preset;
  final String selectedAngle;
  final bool isSelected;
  final VoidCallback onSelect;

  const _BackgroundCard({
    required this.preset,
    required this.selectedAngle,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;
    final variant = preset.variantByAngle(selectedAngle) ?? preset.defaultVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacing12),
      child: AppCard(
        selected: isSelected,
        padding: EdgeInsets.zero,
        onTap: onSelect,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusCard)),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: BackgroundScenePreview(
                  preset: preset,
                  angle: selectedAngle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preset.name,
                          style: tokens.textStyle(fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (preset.isCustom)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: tokens.surfaceMuted,
                            borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
                          ),
                          child: Text(
                            s.personal,
                            style: tokens.textStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tokens.textSecondary),
                          ),
                        ),
                    ],
                  ),
                  if (preset.description != null) ...[
                    const SizedBox(height: DesignTokens.spacing8),
                    Text(
                      preset.description!,
                      style: tokens.textStyle(fontSize: 14, fontWeight: FontWeight.w400, color: tokens.textSecondary),
                    ),
                  ],
                  if (variant != null) ...[
                    const SizedBox(height: DesignTokens.spacing12),
                    Wrap(
                      spacing: DesignTokens.spacing8,
                      runSpacing: DesignTokens.spacing8,
                      children: preset.variants
                          .map(
                            (v) => Chip(
                              label: Text(v.angleLabel),
                              backgroundColor: v.angle == selectedAngle ? tokens.accent : tokens.surfaceMuted,
                              labelStyle: tokens.textStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: v.angle == selectedAngle ? tokens.onAccent : tokens.textPrimary,
                              ),
                              side: BorderSide.none,
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: DesignTokens.spacing12),
                  AppButton(
                    label: isSelected ? s.useThisBackground : s.selectBackground,
                    variant: isSelected ? AppButtonVariant.primary : AppButtonVariant.secondary,
                    expanded: true,
                    onPressed: onSelect,
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
