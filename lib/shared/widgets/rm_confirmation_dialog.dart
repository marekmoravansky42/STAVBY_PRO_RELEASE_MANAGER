import 'package:flutter/material.dart';

class RMConfirmationDialog extends StatelessWidget {
  const RMConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'POTVRDIŤ',
    this.cancelLabel = 'ZRUŠIŤ',
    this.destructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'POTVRDIŤ',
    String cancelLabel = 'ZRUŠIŤ',
    bool destructive = false,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => RMConfirmationDialog(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          destructive: destructive,
        ),
      ) ?? false;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelLabel)),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error)
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      );
}
