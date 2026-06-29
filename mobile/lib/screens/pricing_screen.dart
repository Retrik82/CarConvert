import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
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
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _success;
  double _currentPrice = 0.22;
  ServicePricingEstimate? _generationEstimate;

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
      final price = await SettingsRepository.instance.getGenerationPrice();
      AdminPricingEstimate? estimate;
      try {
        estimate = await SettingsRepository.instance.getPricingEstimate();
      } catch (_) {
        estimate = null;
      }
      _currentPrice = price;
      _generationEstimate = estimate?.generation;
      _priceController.text = price.toStringAsFixed(2);
    } catch (e) {
      _error = userFacingError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyRecommendedGenerationPrice() {
    final recommended = _generationEstimate?.recommendedPriceUsd;
    if (recommended == null) return;
    _priceController.text = recommended.toStringAsFixed(2);
    setState(() => _success = null);
  }

  String _costRange(AppStrings strings, ServicePricingEstimate estimate) {
    if (estimate.actualCostMinUsd == estimate.actualCostMaxUsd) {
      return MoneyFormat.usd(estimate.actualCostMinUsd);
    }
    return '${MoneyFormat.usd(estimate.actualCostMinUsd)} – ${MoneyFormat.usd(estimate.actualCostMaxUsd)}';
  }

  String? _marginLabel(AppStrings strings, double charged, ServicePricingEstimate estimate) {
    if (estimate.actualCostMaxUsd <= 0) return null;
    final margin = ((charged / estimate.actualCostMaxUsd) - 1) * 100;
    if (margin.isNaN || margin.isInfinite) return null;
    final rounded = margin.round();
    if (rounded >= 0) return strings.adminMarginPositive(rounded);
    return strings.adminMarginNegative(rounded.abs());
  }

  Widget _buildCostInsights(AppStrings strings) {
    final estimate = _generationEstimate;
    if (estimate == null) return const SizedBox.shrink();

    final tokens = context.tokens;
    final margin = _marginLabel(strings, _currentPrice, estimate);

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
                strings.adminCostInsightsTitle,
                style: tokens.textStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: DesignTokens.spacing4),
              Text(
                '${strings.adminCostRange}: ${_costRange(strings, estimate)}',
                style: tokens.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: DesignTokens.spacing4),
              Text(
                '${strings.adminRecommended}: ${MoneyFormat.usd(estimate.recommendedPriceUsd)}',
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
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _applyRecommendedGenerationPrice,
                  child: Text(strings.adminApplyRecommended),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final parsed = double.parse(_priceController.text.replaceAll(',', '.'));
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      final price = await SettingsRepository.instance.setGenerationPrice(parsed);
      _currentPrice = price;
      _priceController.text = price.toStringAsFixed(2);
      if (mounted) setState(() => _success = context.strings.adminPriceUpdated);
    } catch (e) {
      if (mounted) setState(() => _error = userFacingError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = context.strings;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Text(strings.adminPricingTitle),
        actions: [
          if (widget.onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: widget.onLogout,
              tooltip: strings.logout,
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
                      '${strings.adminAccountLabel}: ${AuthRepository.instance.currentUser?.email ?? ''}',
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
                            strings.adminGenerationPrice,
                            style: tokens.textStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: DesignTokens.spacing8),
                          Text(
                            strings.adminCurrentGenerationPrice(MoneyFormat.usd(_currentPrice)),
                            style: tokens.textStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: tokens.textSecondary,
                            ),
                          ),
                          _buildCostInsights(strings),
                          const SizedBox(height: DesignTokens.spacing16),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: Validators.price,
                            style: tokens.textStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            decoration: appInputDecoration(
                              strings.adminGenerationPrice,
                              hint: strings.adminPriceHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) appFormMessage(_error!, isError: true, context: context),
                    if (_success != null) appFormMessage(_success!, isError: false, context: context),
                    const SizedBox(height: DesignTokens.spacing32),
                    AppButton(
                      label: strings.adminSave,
                      loading: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
