import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../models/pricing_estimate.dart';
import '../repositories/auth_repository.dart';
import '../repositories/settings_repository.dart';
import '../utils/error_utils.dart';
import '../utils/money_format.dart';
import '../utils/validators.dart';
import '../widgets/app_logo.dart';
import '../widgets/design_system/app_button.dart';
import '../widgets/design_system/app_card.dart';
import '../widgets/form_fields.dart';

class PricingScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const PricingScreen({super.key, this.onLogout});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _customBackgroundPriceController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _success;
  double _currentPrice = 0.10;
  double _currentCustomBackgroundPrice = 0.50;
  AdminPricingEstimate? _estimate;

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
      final results = await Future.wait([
        SettingsRepository.instance.getGenerationPrice(),
        SettingsRepository.instance.getCustomBackgroundPrice(),
        SettingsRepository.instance.getPricingEstimate(),
      ]);
      final price = results[0] as double;
      final customPrice = results[1] as double;
      final estimate = results[2] as AdminPricingEstimate;
      _currentPrice = price;
      _currentCustomBackgroundPrice = customPrice;
      _estimate = estimate;
      _priceController.text = price.toStringAsFixed(2);
      _customBackgroundPriceController.text = customPrice.toStringAsFixed(2);
    } catch (e) {
      _error = userFacingError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyRecommendedGenerationPrice() {
    final recommended = _estimate?.generation.recommendedPriceUsd;
    if (recommended == null) return;
    _priceController.text = recommended.toStringAsFixed(2);
    setState(() => _success = null);
  }

  void _applyRecommendedCustomBackgroundPrice() {
    final recommended = _estimate?.customBackground.recommendedPriceUsd;
    if (recommended == null) return;
    _customBackgroundPriceController.text = recommended.toStringAsFixed(2);
    setState(() => _success = null);
  }

  String _costRange(ServicePricingEstimate estimate) {
    if (estimate.actualCostMinUsd == estimate.actualCostMaxUsd) {
      return MoneyFormat.usd(estimate.actualCostMinUsd);
    }
    return '${MoneyFormat.usd(estimate.actualCostMinUsd)} – ${MoneyFormat.usd(estimate.actualCostMaxUsd)}';
  }

  String? _marginLabel(double charged, ServicePricingEstimate estimate) {
    if (estimate.actualCostMaxUsd <= 0) return null;
    final margin = ((charged / estimate.actualCostMaxUsd) - 1) * 100;
    if (margin.isNaN || margin.isInfinite) return null;
    final rounded = margin.round();
    if (rounded >= 0) return 'Маржа +$rounded% к макс. себестоимости';
    return 'Ниже себестоимости на ${rounded.abs()}%';
  }

  Widget _buildCostInsights({
    required ServicePricingEstimate estimate,
    required double chargedPrice,
    required VoidCallback onApplyRecommended,
  }) {
    final tokens = context.tokens;
    final margin = _marginLabel(chargedPrice, estimate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: DesignTokens.spacing12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DesignTokens.spacing12),
          decoration: BoxDecoration(
            color: tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Себестоимость OpenRouter',
                style: tokens.textStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: DesignTokens.spacing4),
              Text(
                _costRange(estimate),
                style: tokens.textStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: tokens.accent,
                ),
              ),
              const SizedBox(height: DesignTokens.spacing8),
              Text(
                'Рекомендуемая цена: ${MoneyFormat.usd(estimate.recommendedPriceUsd)}',
                style: tokens.textStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              if (margin != null) ...[
                const SizedBox(height: DesignTokens.spacing4),
                Text(
                  margin,
                  style: tokens.textStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: tokens.textTertiary,
                  ),
                ),
              ],
              const SizedBox(height: DesignTokens.spacing8),
              for (final step in estimate.steps)
                Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.spacing4),
                  child: Text(
                    '• ${step.label}: ${MoneyFormat.usd(step.costUsd)} (${step.model})',
                    style: tokens.textStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onApplyRecommended,
                  child: const Text('Подставить рекомендуемую'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final parsed = double.parse(_priceController.text.replaceAll(',', '.'));
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      final price = await SettingsRepository.instance.setGenerationPrice(parsed);
      final customPrice = double.parse(_customBackgroundPriceController.text.replaceAll(',', '.'));
      final savedCustomPrice = await SettingsRepository.instance.setCustomBackgroundPrice(customPrice);
      _currentPrice = price;
      _currentCustomBackgroundPrice = savedCustomPrice;
      _priceController.text = price.toStringAsFixed(2);
      _customBackgroundPriceController.text = savedCustomPrice.toStringAsFixed(2);
      setState(() => _success = 'Цены обновлены для всех пользователей');
    } catch (e) {
      setState(() => _error = userFacingError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _customBackgroundPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: const Text('Цены приложения'),
        actions: [
          if (widget.onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: widget.onLogout,
              tooltip: 'Logout',
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: tokens.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.screenPaddingH),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppLogo(iconSize: 56, titleSize: 24),
                    const SizedBox(height: DesignTokens.spacing8),
                    Text(
                      'Admin: ${AuthRepository.instance.currentUser?.email ?? ''}',
                      textAlign: TextAlign.center,
                      style: tokens.textStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacing32),
                    AppCard(
                      elevated: true,
                      padding: const EdgeInsets.all(DesignTokens.spacing24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Цена генерации',
                            style: tokens.textStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: DesignTokens.spacing8),
                          Text(
                            'Сейчас: ${MoneyFormat.pricePerGeneration(_currentPrice)}',
                            style: tokens.textStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: tokens.textSecondary,
                            ),
                          ),
                          if (_estimate != null)
                            _buildCostInsights(
                              estimate: _estimate!.generation,
                              chargedPrice: _currentPrice,
                              onApplyRecommended: _applyRecommendedGenerationPrice,
                            ),
                          const SizedBox(height: DesignTokens.spacing16),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: Validators.price,
                            style: tokens.textStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            decoration: appInputDecoration('Цена генерации (USD)', hint: '0.22'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacing16),
                    AppCard(
                      elevated: true,
                      padding: const EdgeInsets.all(DesignTokens.spacing24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Цена кастомного фона',
                            style: tokens.textStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: DesignTokens.spacing8),
                          Text(
                            'Сейчас: ${MoneyFormat.usd(_currentCustomBackgroundPrice)}',
                            style: tokens.textStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: tokens.textSecondary,
                            ),
                          ),
                          if (_estimate != null)
                            _buildCostInsights(
                              estimate: _estimate!.customBackground,
                              chargedPrice: _currentCustomBackgroundPrice,
                              onApplyRecommended: _applyRecommendedCustomBackgroundPrice,
                            ),
                          const SizedBox(height: DesignTokens.spacing16),
                          TextFormField(
                            controller: _customBackgroundPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: Validators.price,
                            style: tokens.textStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            decoration: appInputDecoration('Цена кастомного фона (USD)', hint: '0.50'),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) appFormMessage(_error!, isError: true, context: context),
                    if (_success != null) appFormMessage(_success!, isError: false, context: context),
                    const SizedBox(height: DesignTokens.spacing32),
                    AppButton(
                      label: 'Сохранить',
                      loading: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                    const SizedBox(height: DesignTokens.spacing16),
                    Text(
                      'Себестоимость — оценка OpenRouter по текущим моделям на сервере. '
                      'Рекомендуемая цена = ×2 для генерации и ×1.1 для кастомного фона от типичной себестоимости.',
                      style: tokens.textStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: tokens.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
