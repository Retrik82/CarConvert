import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

InputDecoration appInputDecoration(
  String label, {
  String? hint,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: suffixIcon,
  );
}

Widget appTextField({
  required TextEditingController controller,
  required String label,
  String? hint,
  bool obscureText = false,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
  AutovalidateMode autovalidateMode = AutovalidateMode.onUserInteraction,
}) {
  return TextFormField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    validator: validator,
    autovalidateMode: autovalidateMode,
    style: AppTheme.textStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppTheme.textPrimary),
    decoration: appInputDecoration(label, hint: hint),
  );
}

/// Inline feedback below forms.
Widget appFormMessage(String text, {required bool isError}) {
  return Padding(
    padding: const EdgeInsets.only(top: AppTheme.spacingElement),
    child: Text(
      text,
      style: AppTheme.textStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: isError ? AppTheme.error : AppTheme.success,
      ),
    ),
  );
}
