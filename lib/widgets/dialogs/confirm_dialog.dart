import 'package:flutter/material.dart';

Future<bool?> showConfirmDialog(
  BuildContext context,
  String title,
  String message,
) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
}
