import 'dart:async';

import 'package:flutter/material.dart';

import '../core/assets/bundled_background_catalog.dart';
import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../models/background.dart';
import '../repositories/background_repository.dart';
import '../utils/money_format.dart';
import '../widgets/background_preview_grid.dart';
import '../widgets/background_scene_preview.dart';
import '../widgets/design_system/app_button.dart';
import '../widgets/design_system/app_card.dart';
import '../widgets/form_fields.dart';
import 'background_generation_screen.dart';

class BackgroundsScreen extends StatefulWidget {
  final VoidCallback? onSelected;

  const BackgroundsScreen({super.key, this.onSelected});

  @override
  State<BackgroundsScreen> createState() => _BackgroundsScreenState();
}

class _BackgroundsScreenState extends State<BackgroundsScreen> {
  static const _previewAngle = 'three_quarter_left';

  final _repo = BackgroundRepository.instance;
  final List<BackgroundPreset> _sharedPresets = BundledBackgroundCatalog.catalog.presets;

  List<BackgroundPreset> _customPresets = const [];
  double _customPriceUsd = BundledBackgroundCatalog.catalog.customBackgroundPriceUsd;
  bool _loading = false;
  String? _catalogWarning;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreSelection());
    unawaited(_loadRemoteCatalog(showProgress: false));
  }

  BackgroundCatalog get _screenCatalog => BackgroundCatalog(
        presets: _sharedPresets,
        custom: _customPresets,
        customBackgroundPriceUsd: _customPriceUsd,
      );

  Future<void> _restoreSelection() async {
    await _repo.loadSavedSelection(catalog: _screenCatalog);
    if (!mounted) return;
    if (_repo.selected == null && _sharedPresets.isNotEmpty) {
      await _repo.select(_sharedPresets.first);
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadRemoteCatalog({bool showProgress = true}) async {
    if (!mounted) return;
    if (showProgress) {
      setState(() {
        _loading = true;
        _catalogWarning = null;
      });
    }

    try {
      final remote = await _repo.fetchCatalog();
      final nextCustom = remote.custom;
      final nextPrice = remote.customBackgroundPriceUsd > 0
          ? remote.customBackgroundPriceUsd
          : BundledBackgroundCatalog.catalog.customBackgroundPriceUsd;

      _customPresets = nextCustom;
      _customPriceUsd = nextPrice;

      await _repo.loadSavedSelection(catalog: _screenCatalog);
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _catalogWarning = context.strings.errorGeneric;
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  BackgroundPreset _resolvePreset(BackgroundPreset preset) {
    if (!preset.isCustom) {
      for (final shared in _sharedPresets) {
        if (shared.slug == preset.slug) return shared;
      }
    } else {
      for (final custom in _customPresets) {
        if (custom.id == preset.id) return custom;
      }
    }
    return preset;
  }

  Future<void> _selectPreset(BackgroundPreset preset) async {
    final resolved = _resolvePreset(preset);
    await _repo.select(resolved);
    if (!mounted) return;

    setState(() {});
    widget.onSelected?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${context.strings.backgroundSelected}: ${resolved.name}')),
    );
    Navigator.pop(context, _repo.selected);
  }

  Future<void> _showCreateSheet() async {
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
                  '${s.customBackgroundPrice} ${MoneyFormat.usd(_customPriceUsd)}',
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
                  label: s.generate,
                  onPressed: () async {
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
    final selected = await Navigator.push<SelectedBackground?>(
      context,
      MaterialPageRoute(
        builder: (_) => BackgroundGenerationScreen(
          name: name,
          prompt: prompt,
          priceUsd: _customPriceUsd,
        ),
      ),
    );

    if (!mounted) return;
    if (selected != null) {
      widget.onSelected?.call();
      Navigator.pop(context, selected);
      return;
    }
    await _loadRemoteCatalog();
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
            onPressed: _showCreateSheet,
            icon: const Icon(Icons.auto_awesome_outlined, size: 18),
            label: Text(s.customBackground),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRemoteCatalog,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(DesignTokens.screenPaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_loading)
                Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.spacing16),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: tokens.accent,
                    backgroundColor: tokens.surfaceMuted,
                  ),
                ),
              Text(
                s.backgroundsIntro,
                style: tokens.textStyle(fontSize: 15, fontWeight: FontWeight.w400, color: tokens.textSecondary),
              ),
              if (_catalogWarning != null) ...[
                const SizedBox(height: DesignTokens.spacing12),
                AppCard(
                  padding: const EdgeInsets.all(DesignTokens.spacing12),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 18, color: tokens.textSecondary),
                      const SizedBox(width: DesignTokens.spacing8),
                      Expanded(
                        child: Text(
                          _catalogWarning!,
                          style: tokens.textStyle(fontSize: 13, fontWeight: FontWeight.w400, color: tokens.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (selected != null) ...[
                const SizedBox(height: DesignTokens.spacing16),
                _SelectedBanner(selected: selected, previewAngle: _previewAngle),
              ],
              const SizedBox(height: DesignTokens.spacing24),
              Text(s.sharedBackgrounds, style: tokens.textStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: DesignTokens.spacing12),
              ..._sharedPresets.map(
                (preset) => _BackgroundCard(
                  preset: preset,
                  previewAngle: _previewAngle,
                  isSelected: selected?.preset.slug == preset.slug,
                  onSelect: () => _selectPreset(preset),
                  onPreviewAngles: () => openBackgroundDetailSheet(
                    context,
                    preset: preset,
                    isSelected: selected?.preset.slug == preset.slug,
                    onSelect: () => _selectPreset(preset),
                  ),
                ),
              ),
              if (_customPresets.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.spacing24),
                Text(s.yourBackgrounds, style: tokens.textStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: DesignTokens.spacing12),
                ..._customPresets.map(
                  (preset) => _BackgroundCard(
                    preset: preset,
                    previewAngle: _previewAngle,
                    isSelected: selected?.preset.id == preset.id,
                    onSelect: () => _selectPreset(preset),
                    onPreviewAngles: () => openBackgroundDetailSheet(
                      context,
                      preset: preset,
                      isSelected: selected?.preset.id == preset.id,
                      onSelect: () => _selectPreset(preset),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: DesignTokens.spacing32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedBanner extends StatelessWidget {
  final SelectedBackground selected;
  final String previewAngle;

  const _SelectedBanner({
    required this.selected,
    required this.previewAngle,
  });

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
              width: 104,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _BackgroundCardPreview(
                  preset: selected.preset,
                  angle: previewAngle,
                ),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.spacing12),
          Expanded(
            child: Text(
              '${s.backgroundSelected}: ${selected.displayName}',
              style: tokens.textStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
  final String previewAngle;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onPreviewAngles;

  const _BackgroundCard({
    required this.preset,
    required this.previewAngle,
    required this.isSelected,
    required this.onSelect,
    required this.onPreviewAngles,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacing16),
      child: AppCard(
        selected: isSelected,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: onPreviewAngles,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(DesignTokens.radiusCard),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: _BackgroundCardPreview(
                          preset: preset,
                          angle: previewAngle,
                        ),
                      ),
                    if (isSelected)
                      Positioned(
                        top: DesignTokens.spacing12,
                        left: DesignTokens.spacing12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: tokens.primaryGradient,
                            borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                s.backgroundSelected,
                                style: tokens.textStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      right: DesignTokens.spacing12,
                      bottom: DesignTokens.spacing12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              s.backgroundTapToExpand,
                              style: tokens.textStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
                  const SizedBox(height: DesignTokens.spacing12),
                  AppButton(
                    label: s.backgroundTapToExpand,
                    variant: AppButtonVariant.secondary,
                    icon: Icons.fullscreen_rounded,
                    expanded: true,
                    onPressed: onPreviewAngles,
                  ),
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

class _BackgroundCardPreview extends StatelessWidget {
  final BackgroundPreset preset;
  final String angle;

  const _BackgroundCardPreview({
    required this.preset,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return BackgroundScenePreview(
      preset: preset,
      angle: angle,
      fit: BoxFit.cover,
    );
  }
}
