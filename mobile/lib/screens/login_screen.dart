import 'package:flutter/material.dart';

import '../repositories/auth_repository.dart';
import '../theme/app_theme.dart';
import '../utils/error_utils.dart';
import '../utils/validators.dart';
import '../widgets/app_logo.dart';
import '../widgets/form_fields.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

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
      if (mounted) widget.onLoggedIn();
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingScreenH),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const AppLogo(showTagline: true),
                const SizedBox(height: AppTheme.spacingSection),
                appTextField(
                  controller: _email,
                  label: 'Email or username',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.loginIdentifier,
                ),
                const SizedBox(height: AppTheme.spacingElement),
                appTextField(
                  controller: _password,
                  label: 'Password',
                  obscureText: true,
                  validator: Validators.loginPassword,
                ),
                if (_error != null) appFormMessage(_error!, isError: true),
                const SizedBox(height: AppTheme.spacingSection),
                FilledButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white),
                        )
                      : const Text('Login'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegisterScreen(onRegistered: widget.onLoggedIn),
                      ),
                    );
                  },
                  child: const Text('Register'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                  child: Text(
                    'Forgot Password',
                    style: AppTheme.textStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppTheme.textSecondary),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
