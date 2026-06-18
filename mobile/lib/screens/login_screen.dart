import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../repositories/auth_repository.dart';
import '../utils/error_utils.dart';
import '../utils/validators.dart';
import '../widgets/app_logo.dart';
import '../widgets/design_system/app_button.dart';
import '../widgets/design_system/car_hero.dart';
import '../widgets/form_fields.dart';
import 'forgot_password_screen.dart';
class LoginScreen extends StatefulWidget {
  final VoidCallback onLoggedIn;

  const LoginScreen({super.key, required this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthRepository.instance.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      widget.onLoggedIn();
    } catch (e) {
      setState(() => _error = userFacingError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
                const SizedBox(height: DesignTokens.spacing8),
                const Center(child: AppLogo(iconSize: 40, titleSize: 22, showTagline: false)),
                const SizedBox(height: DesignTokens.spacing24),
                CarHero(height: 140, animate: false),
                const SizedBox(height: DesignTokens.spacing32),
                Text(
                  s.login,
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
                  controller: _email,
                  label: s.emailOrUsername,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.loginIdentifier,
                ),
                const SizedBox(height: DesignTokens.spacing16),
                appTextField(
                  context: context,
                  controller: _password,
                  label: s.password,
                  obscureText: true,
                  validator: Validators.loginPassword,
                ),
                if (_error != null) appFormMessage(_error!, isError: true, context: context),
                const SizedBox(height: DesignTokens.spacing24),
                AppButton(
                  label: s.login,
                  loading: _loading,
                  onPressed: _loading ? null : _login,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                  child: Text(
                    s.forgotPassword,
                    style: tokens.textStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: tokens.textSecondary,
                    ),
                  ),
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
