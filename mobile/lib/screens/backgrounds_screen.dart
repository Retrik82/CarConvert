import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../core/assets/bundled_background_catalog.dart';
import '../models/background.dart';
import '../repositories/background_repository.dart';
import '../utils/money_format.dart';
import '../widgets/background_preview_grid.dart';
import '../widgets/background_scene_preview.dart';
import '../widgets/design_system/app_button.dart';
import '../widgets/design_system/app_card.dart';
import '../widgets/design_system/state_views.dart';
import '../widgets/form_fields.dart';
import 'background_generation_screen.dart';

class BackgroundsScreen extends StatefulWidget {
  final VoidCallback? onSelected;

  const BackgroundsScreen({super.key, this.onSelected});

  @override
  State<BackgroundsScreen> createState() => _BackgroundsScreenState();
}

class _BackgroundsScreenState extends State<BackgroundsScreen> {
  final _repo = BackgroundRepository.instance;
  BackgroundCatalog? _catalog = BundledBackgroundCatalog.catalog;
  bool _loading = true;
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
    _repo.clearImageCache();
    try {
      final catalog = await _repo.fetchCatalog();
      await _repo.loadSavedSelection(catalog: catalog);
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        if (_repo.selected == null && catalog.presets.isNotEmpty) {
          _repo.select(catalog.presets.first);
        }
      });
    } catch (e) {
      if (mounted) {
        final fallback = BundledBackgroundCatalog.catalog;
        await _repo.loadSavedSelection(catalog: fallback);
        setState(() {
          _catalog = fallback;
          _error = null;
          if (_repo.selected == null && fallback.presets.isNotEmpty) {
            _repo.select(fallback.presets.first);
          }
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  BackgroundCatalog get _displayCatalog {
    return BackgroundRepository.mergeWithDefaultPresets(
      _catalog ?? BundledBackgroundCatalog.catalog,
    );
  }

  Future<void> _selectPreset(BackgroundPreset preset) async {
    await _repo.select(preset);
    if (!mounted) return;
    setState(() {});
    widget.onSelected?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${context.strings.backgroundSelected}: ${preset.name}')),
    );
    Navigator.pop(context, _repo.selected);
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
    final catalog = _catalog;
    if (catalog == null) return;

    final selected = await Navigator.push<SelectedBackground?>(
      context,
      MaterialPageRoute(
        builder: (_) => BackgroundGenerationScreen(
          name: name,
          prompt: prompt,
          priceUsd: catalog.customBackgroundPriceUsd,
        ),
      ),
    );

    if (!mounted) return;
    if (selected != null) {
      widget.onSelected?.call();
      Navigator.pop(context, selected);
    } else {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;
    final selected = _repo.selected;
    final catalog = _displayCatalog;

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
      body: _error != null
          ? ErrorStateView(message: _error!, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(DesignTokens.screenPaddingH),
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
                  if (selected != null) ...[
                    const SizedBox(height: DesignTokens.spacing16),
                    _SelectedBanner(selected: selected),
                  ],
                  const SizedBox(height: DesignTokens.spacing24),
                  if (catalog.presets.isNotEmpty) ...[
                    Text(s.sharedBackgrounds, style: tokens.textStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: DesignTokens.spacing12),
                    ...catalog.presets.map(
                      (preset) => _BackgroundCard(
                        preset: preset,
                        isSelected: selected?.preset.slug == preset.slug,
                        onSelect: () => _selectPreset(preset),
                      ),
                    ),
                  ],
                  if (catalog.custom.isNotEmpty) ...[
                    const SizedBox(height: DesignTokens.spacing24),
                    Text(s.yourBackgrounds, style: tokens.textStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: DesignTokens.spacing12),
                    ...catalog.custom.map(
                      (preset) => _BackgroundCard(
                        preset: preset,
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

class _SelectedBanner extends StatelessWidget {
  final SelectedBackground selected;

  const _SelectedBanner({required this.selected});

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
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: SizedBox(
                width: 96,
                child: BackgroundScenePreview(
                  preset: selected.preset,
                  angle: 'three_quarter_left',
                  borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
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
  final bool isSelected;
  final VoidCallback onSelect;

  const _BackgroundCard({
    required this.preset,
    required this.isSelected,
    required this.onSelect,
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
              onTap: () => openBackgroundDetailSheet(
                context,
                preset: preset,
                isSelected: isSelected,
                onSelect: onSelect,
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    BackgroundScenePreview(
                      preset: preset,
                      angle: 'three_quarter_left',
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
