import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../repositories/auth_repository.dart';
import '../utils/error_utils.dart';
import '../utils/validators.dart';
import '../widgets/app_logo.dart';
import '../widgets/design_system/app_button.dart';
import '../widgets/form_fields.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _sent = false;

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthRepository.instance.forgotPassword(_email.text.trim());
      setState(() => _sent = true);
    } catch (e) {
      setState(() => _error = userFacingError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Forgot Password'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.screenPaddingH),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AppLogo(iconSize: 36, titleSize: 20, showTagline: false)),
                const SizedBox(height: DesignTokens.spacing24),
                Text(
                  'Enter your email and we will send a reset link if the account exists.',
                  style: tokens.textStyle(fontSize: 15, fontWeight: FontWeight.w400, color: tokens.textSecondary),
                ),
                const SizedBox(height: DesignTokens.spacing24),
                appTextField(
                  context: context,
                  controller: _email,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                if (_error != null) appFormMessage(_error!, isError: true, context: context),
                if (_sent)
                  appFormMessage(
                    'If an account exists, a reset link has been sent.',
                    isError: false,
                    context: context,
                  ),
                const Spacer(),
                AppButton(
                  label: 'Send reset link',
                  icon: Icons.mail_outline_rounded,
                  loading: _loading,
                  onPressed: _loading || _sent ? null : _send,
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
