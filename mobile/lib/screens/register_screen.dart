import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/debug_log.dart';
import '../utils/error_utils.dart';
import '../utils/validators.dart';
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
      await AuthService.instance.register(
        _email.text.trim(),
        _password.text,
        _name.text.trim(),
      );
      // #region agent log
      if (mounted) {
        DebugLog.emit('register_screen.dart:_register', 'register API ok, before onRegistered', hypothesisId: 'A', data: {'canPop': Navigator.of(context).canPop});
      }
      // #endregion
      if (mounted) widget.onRegistered();
      // #region agent log
      if (mounted) {
        DebugLog.emit('register_screen.dart:_register', 'after onRegistered, still mounted on RegisterScreen', hypothesisId: 'A', data: {'canPop': Navigator.of(context).canPop});
      }
      // #endregion
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
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              appTextField(
                controller: _name,
                label: 'Name',
                validator: (v) => Validators.required(v, 'Name'),
              ),
              const SizedBox(height: 16),
              appTextField(
                controller: _email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              appTextField(
                controller: _password,
                label: 'Password',
                obscureText: true,
                validator: Validators.password,
              ),
              const SizedBox(height: 16),
              appTextField(
                controller: _confirmPassword,
                label: 'Confirm password',
                obscureText: true,
                validator: (v) => Validators.confirmPassword(v, _password.text),
              ),
              if (_error != null) appFormMessage(_error!, isError: true),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
