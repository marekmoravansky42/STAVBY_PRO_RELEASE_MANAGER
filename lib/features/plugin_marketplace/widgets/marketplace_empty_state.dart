import 'package:flutter/material.dart';

class MarketplaceEmptyState extends StatelessWidget {
  const MarketplaceEmptyState({
    super.key,
    required this.hasFilters,
    required this.onClearFilters,
    required this.onRefresh,
  });

  final bool hasFilters;
  final VoidCallback onClearFilters;
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
              hasFilters
                  ? 'Žiadny plugin nezodpovedá filtru.'
                  : 'Marketplace zatiaľ neobsahuje žiadne pluginy.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (hasFilters)
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Zrušiť filtre'),
              )
            else
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
