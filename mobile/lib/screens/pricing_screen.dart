import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
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
      final customPrice = await SettingsRepository.instance.getCustomBackgroundPrice();
      _currentPrice = price;
      _currentCustomBackgroundPrice = customPrice;
      _priceController.text = price.toStringAsFixed(2);
      _customBackgroundPriceController.text = customPrice.toStringAsFixed(2);
    } catch (e) {
      _error = userFacingError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
      setState(() => _success = 'Prices updated for all users');
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
        title: const Text('App Pricing'),
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
                            'Generation price',
                            style: tokens.textStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: DesignTokens.spacing8),
                          Text(
                            'Current: ${MoneyFormat.pricePerGeneration(_currentPrice)}',
                            style: tokens.textStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: tokens.textSecondary,
                            ),
                          ),
                          const SizedBox(height: DesignTokens.spacing16),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: Validators.price,
                            style: tokens.textStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            decoration: appInputDecoration('Generation price (USD)', hint: '0.10'),
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
                            'Custom background price',
                            style: tokens.textStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: DesignTokens.spacing8),
                          Text(
                            'Current: ${MoneyFormat.usd(_currentCustomBackgroundPrice)}',
                            style: tokens.textStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: tokens.textSecondary,
                            ),
                          ),
                          const SizedBox(height: DesignTokens.spacing16),
                          TextFormField(
                            controller: _customBackgroundPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: Validators.price,
                            style: tokens.textStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            decoration: appInputDecoration('Custom background price (USD)', hint: '0.50'),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) appFormMessage(_error!, isError: true, context: context),
                    if (_success != null) appFormMessage(_success!, isError: false, context: context),
                    const SizedBox(height: DesignTokens.spacing32),
                    AppButton(
                      label: 'Save',
                      loading: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                    const SizedBox(height: DesignTokens.spacing16),
                    Text(
                      'Generation price applies per render. Custom background price is charged once when a user creates a personal background.',
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
