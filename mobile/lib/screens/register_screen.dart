import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../repositories/auth_repository.dart';
import '../utils/error_utils.dart';
import '../utils/validators.dart';
import '../widgets/app_logo.dart';
import '../widgets/design_system/app_button.dart';
import '../widgets/design_system/auth_hero_background.dart';
import '../widgets/form_fields.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onRegistered;

  const RegisterScreen({super.key, required this.onRegistered});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthRepository.instance.register(
        _email.text.trim(),
        _password.text,
        _name.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      widget.onRegistered();
    } catch (e) {
      setState(() => _error = userFacingError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.screenPaddingH),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: AppLogo(iconSize: 44, titleSize: 24, useImageLogo: true, showTagline: true),
                ),
                const SizedBox(height: DesignTokens.spacing24),
                const AuthHeroBackground(height: 160),
                const SizedBox(height: DesignTokens.spacing24),
                Text(
                  s.register,
                  style: tokens.textStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                ),
                const SizedBox(height: DesignTokens.spacing8),
                Text(
                  s.appTagline,
                  style: tokens.textStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing32),
                appTextField(
                  context: context,
                  controller: _name,
                  label: 'Name',
                  validator: (v) => Validators.required(v, 'Name'),
                ),
                const SizedBox(height: DesignTokens.spacing16),
                appTextField(
                  context: context,
                  controller: _email,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: DesignTokens.spacing16),
                appTextField(
                  context: context,
                  controller: _password,
                  label: s.password,
                  obscureText: true,
                  validator: Validators.password,
                ),
                const SizedBox(height: DesignTokens.spacing16),
                appTextField(
                  context: context,
                  controller: _confirmPassword,
                  label: 'Confirm password',
                  obscureText: true,
                  validator: (v) => Validators.confirmPassword(v, _password.text),
                ),
                if (_error != null) appFormMessage(_error!, isError: true, context: context),
                const SizedBox(height: DesignTokens.spacing32),
                AppButton(
                  label: s.register,
                  loading: _loading,
                  onPressed: _loading ? null : _register,
                ),
                const SizedBox(height: DesignTokens.spacing32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
