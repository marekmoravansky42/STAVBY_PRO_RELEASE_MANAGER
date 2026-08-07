import 'package:flutter/material.dart';

class PluginEmptyState extends StatelessWidget {
  const PluginEmptyState({super.key, required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.extension_off_outlined, size: 48),
            const SizedBox(height: 16),
            Text(
              'Neboli nájdené žiadne pluginy.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Obnoviť'),
            ),
          ],
        ),
      ),
    );
  }
}
