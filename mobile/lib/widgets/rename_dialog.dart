import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import 'form_fields.dart';

Future<String?> showRenameDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String hint,
  required String initialValue,
}) {
  final controller = TextEditingController(text: initialValue);
  final s = context.strings;

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: appInputDecoration(label, hint: hint),
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (v) {
          final trimmed = v.trim();
          if (trimmed.isNotEmpty) Navigator.pop(ctx, trimmed);
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
        TextButton(
          onPressed: () {
            final trimmed = controller.text.trim();
            if (trimmed.isNotEmpty) Navigator.pop(ctx, trimmed);
          },
          child: Text(s.confirm),
        ),
      ],
    ),
  );
}
