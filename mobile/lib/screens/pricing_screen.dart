import 'package:flutter/material.dart';

import '../repositories/auth_repository.dart';
import '../repositories/settings_repository.dart';
import '../theme/app_theme.dart';
import '../utils/error_utils.dart';
import '../utils/money_format.dart';
import '../utils/validators.dart';
import '../widgets/app_logo.dart';
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
    return Scaffold(
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
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingScreenH),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppLogo(iconSize: 56, titleSize: 24),
                    const SizedBox(height: 8),
                    Text(
                      'Admin: ${AuthRepository.instance.currentUser?.email ?? ''}',
                      textAlign: TextAlign.center,
                      style: AppTheme.textStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: AppTheme.spacingSection),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generation price',
                            style: AppTheme.textStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Current: ${MoneyFormat.pricePerGeneration(_currentPrice)}',
                            style: AppTheme.textStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: Validators.price,
                            style: AppTheme.textStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppTheme.textPrimary),
                            decoration: appInputDecoration('Generation price (USD)', hint: '0.10'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingElement),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Custom background price',
                            style: AppTheme.textStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Current: ${MoneyFormat.usd(_currentCustomBackgroundPrice)}',
                            style: AppTheme.textStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _customBackgroundPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: Validators.price,
                            style: AppTheme.textStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppTheme.textPrimary),
                            decoration: appInputDecoration('Custom background price (USD)', hint: '0.50'),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) appFormMessage(_error!, isError: true),
                    if (_success != null) appFormMessage(_success!, isError: false),
                    const SizedBox(height: AppTheme.spacingSection),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Generation price applies per render. Custom background price is charged once when a user creates a personal background.',
                      style: AppTheme.textStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppTheme.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
