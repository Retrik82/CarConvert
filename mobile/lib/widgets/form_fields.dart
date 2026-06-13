import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';

InputDecoration appInputDecoration(
  String label, {
  BuildContext? context,
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
  required BuildContext context,
  required TextEditingController controller,
  required String label,
  String? hint,
  bool obscureText = false,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
  AutovalidateMode autovalidateMode = AutovalidateMode.onUserInteraction,
}) {
  final tokens = context.tokens;
  return TextFormField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    validator: validator,
    autovalidateMode: autovalidateMode,
    style: tokens.textStyle(fontSize: 16, fontWeight: FontWeight.w400),
    decoration: appInputDecoration(label, hint: hint),
  );
}

Widget appFormMessage(String text, {required bool isError, BuildContext? context}) {
  final tokens = context != null ? context.tokens : AppTokens.light;
  return Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Text(
      text,
      style: tokens.textStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: isError ? tokens.error : tokens.success,
      ),
    ),
  );
}
