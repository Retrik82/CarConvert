import 'package:flutter/material.dart';

import '../models/background.dart';
import '../repositories/auth_repository.dart';
import '../repositories/background_repository.dart';
import '../theme/app_theme.dart';
import '../utils/error_utils.dart';
import '../utils/money_format.dart';
import '../widgets/authenticated_background_image.dart';
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
  BackgroundPreset? _expandedPreset;
  String _selectedAngle = 'three_quarter_left';
  bool _loading = true;
  bool _creating = false;
  String? _error;

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
    try {
      final catalog = await _repo.fetchCatalog();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _expandedPreset ??= catalog.presets.isNotEmpty ? catalog.presets.first : null;
        if (_repo.selected == null && catalog.presets.isNotEmpty) {
          final preset = catalog.presets.first;
          final variant = preset.defaultVariant;
          if (variant != null) {
            _repo.select(preset, variant);
          }
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

    final nameController = TextEditingController();
    final promptController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showModalBottomSheet<BackgroundPreset>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create custom background',
                  style: AppTheme.textStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your personal background will be saved and available only to you. '
                  'Price: ${MoneyFormat.usd(catalog.customBackgroundPriceUsd)}',
                  style: AppTheme.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameController,
                  decoration: appInputDecoration('Name', hint: 'My studio'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: promptController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: appInputDecoration(
                    'Prompt',
                    hint: 'Describe the empty environment for your car renders...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 10) {
                      return 'Prompt must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _creating
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(ctx);
                          await _createCustom(
                            nameController.text.trim(),
                            promptController.text.trim(),
                          );
                        },
                  child: _creating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Generate for ${MoneyFormat.usd(catalog.customBackgroundPriceUsd)}'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (created != null) {
      _selectPreset(created);
    }
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
      await AuthRepository.instance.refreshCurrentUser();
      await _load();
      if (!mounted) return;
      setState(() => _expandedPreset = preset);
      _selectPreset(preset);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _repo.selected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backgrounds'),
        actions: [
          TextButton.icon(
            onPressed: _creating ? null : _showCreateSheet,
            icon: const Icon(Icons.auto_awesome_outlined, size: 18),
            label: const Text('Custom'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(AppTheme.spacingScreenH),
                    children: [
                      Text(
                        'Choose a scene before capture',
                        style: AppTheme.textStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Each background includes 7 perspective variants for different car angles.',
                        style: AppTheme.textStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _AngleSelector(
                        selectedAngle: _selectedAngle,
                        onChanged: (angle) => setState(() => _selectedAngle = angle),
                      ),
                      if (selected != null) ...[
                        const SizedBox(height: 16),
                        _SelectedBanner(selected: selected),
                      ],
                      const SizedBox(height: 24),
                      if (_catalog!.presets.isNotEmpty) ...[
                        _SectionTitle(title: 'Shared backgrounds'),
                        const SizedBox(height: 12),
                        ..._catalog!.presets.map(
                          (preset) => _BackgroundCard(
                            preset: preset,
                            selectedAngle: _selectedAngle,
                            isSelected: selected?.preset.id == preset.id && !preset.isCustom,
                            isExpanded: _expandedPreset?.id == preset.id,
                            onExpand: () => setState(() => _expandedPreset = preset),
                            onSelect: () => _selectPreset(preset),
                          ),
                        ),
                      ],
                      if (_catalog!.custom.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _SectionTitle(title: 'Your backgrounds'),
                        const SizedBox(height: 12),
                        ..._catalog!.custom.map(
                          (preset) => _BackgroundCard(
                            preset: preset,
                            selectedAngle: _selectedAngle,
                            isSelected: selected?.preset.id == preset.id && preset.isCustom,
                            isExpanded: _expandedPreset?.id == preset.id,
                            onExpand: () => setState(() => _expandedPreset = preset),
                            onSelect: () => _selectPreset(preset),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTheme.textStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }
}

class _AngleSelector extends StatelessWidget {
  final String selectedAngle;
  final ValueChanged<String> onChanged;

  const _AngleSelector({
    required this.selectedAngle,
    required this.onChanged,
  });

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
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _angles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (angle, label) = _angles[index];
          final selected = angle == selectedAngle;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => onChanged(angle),
            selectedColor: AppTheme.accent,
            labelStyle: TextStyle(color: selected ? AppTheme.white : AppTheme.textPrimary),
          );
        },
      ),
    );
  }
}

class _SelectedBanner extends StatelessWidget {
  final SelectedBackground selected;

  const _SelectedBanner({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration(color: AppTheme.surfaceMuted, showBorder: true),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: AuthenticatedBackgroundImage(
                previewPath: selected.previewUrl,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected: ${selected.displayName}',
                  style: AppTheme.textStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  selected.variant.angleLabel,
                  style: AppTheme.textStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppTheme.success),
        ],
      ),
    );
  }
}

class _BackgroundCard extends StatelessWidget {
  final BackgroundPreset preset;
  final String selectedAngle;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onExpand;
  final VoidCallback onSelect;

  const _BackgroundCard({
    required this.preset,
    required this.selectedAngle,
    required this.isSelected,
    required this.isExpanded,
    required this.onExpand,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final variant = preset.variantByAngle(selectedAngle) ?? preset.defaultVariant;
    final previewPath = variant?.previewUrl ?? preset.previewUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          onTap: onExpand,
          child: Container(
            decoration: AppTheme.cardDecoration(
              showBorder: true,
              color: isSelected ? AppTheme.surfaceMuted : AppTheme.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusCard)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: AuthenticatedBackgroundImage(previewPath: previewPath),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              preset.name,
                              style: AppTheme.textStyle(fontSize: 17, fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (preset.isCustom)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Personal',
                                style: AppTheme.textStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (preset.description != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          preset.description!,
                          style: AppTheme.textStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                      if (isExpanded) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: preset.variants
                              .map(
                                (item) => Chip(
                                  label: Text(item.angleLabel),
                                  backgroundColor: item.angle == selectedAngle
                                      ? AppTheme.accent
                                      : AppTheme.surfaceMuted,
                                  labelStyle: TextStyle(
                                    color: item.angle == selectedAngle
                                        ? AppTheme.white
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: onSelect,
                          child: Text(isSelected ? 'Use this background' : 'Select background'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
