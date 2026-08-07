import 'package:flutter/material.dart';

class RMPrimaryButton extends StatelessWidget {
  const RMPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => icon == null
      ? FilledButton(
          onPressed: onPressed,
          child: _RMButtonLabel(label: label),
        )
      : FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: _RMButtonLabel(label: label),
        );
}

class RMSecondaryButton extends StatelessWidget {
  const RMSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => icon == null
      ? OutlinedButton(
          onPressed: onPressed,
          child: _RMButtonLabel(label: label),
        )
      : OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: _RMButtonLabel(label: label),
        );
}

class _RMButtonLabel extends StatelessWidget {
  const _RMButtonLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      );
}
