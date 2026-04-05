import 'package:flutter/material.dart';

Future<String?> showProfileFieldEditDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String initialValue,
}) async {
  final controller = TextEditingController(text: initialValue);
  String? errorText;

  try {
    return await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        void submit(StateSetter setDialogState) {
          final trimmed = controller.text.trim();
          if (trimmed.isEmpty) {
            setDialogState(() => errorText = 'Kotelezo mezo');
            return;
          }
          Navigator.of(dialogContext).pop(trimmed);
        }

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: label,
                errorText: errorText,
              ),
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (errorText != null) {
                  setDialogState(() => errorText = null);
                }
              },
              onSubmitted: (_) => submit(setDialogState),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Megse'),
              ),
              FilledButton(
                onPressed: () => submit(setDialogState),
                child: const Text('Mentes'),
              ),
            ],
          ),
        );
      },
    );
  } finally {
    controller.dispose();
  }
}
