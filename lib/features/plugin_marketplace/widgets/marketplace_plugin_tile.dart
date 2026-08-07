import 'package:flutter/material.dart';

import '../../../core/plugin_marketplace/plugin_marketplace_manifest.dart';

class MarketplacePluginTile extends StatelessWidget {
  const MarketplacePluginTile({
    super.key,
    required this.plugin,
    required this.currentApiVersion,
    this.onValidateInstallation,
    this.onInstall,
    this.onCreateTestPlugin,
  });

  final PluginMarketplaceManifest plugin;
  final String currentApiVersion;
  final VoidCallback? onValidateInstallation;
  final VoidCallback? onInstall;
  final VoidCallback? onCreateTestPlugin;

  @override
  Widget build(BuildContext context) {
    final compatible = currentApiVersion.isEmpty ||
        plugin.apiVersion == currentApiVersion;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.extension_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plugin.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text('${plugin.author} • ${plugin.id}'),
                    ],
                  ),
                ),
                Chip(
                  avatar: Icon(
                    compatible ? Icons.check_circle_outline : Icons.warning_amber,
                    size: 18,
                  ),
                  label: Text(compatible ? 'Kompatibilný' : 'Iné API'),
                ),
              ],
            ),
            if (plugin.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(plugin.description),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Verzia ${plugin.version}')),
                Chip(label: Text('API ${plugin.apiVersion}')),
                ...plugin.categories.map((category) => Chip(label: Text(category))),
              ],
            ),
            if (onValidateInstallation != null ||
                onInstall != null ||
                onCreateTestPlugin != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (onCreateTestPlugin != null)
                      OutlinedButton.icon(
                        onPressed: onCreateTestPlugin,
                        icon: const Icon(Icons.add_box_outlined),
                        label: const Text('Vytvoriť testovací plugin'),
                      ),
                    if (onValidateInstallation != null)
                      OutlinedButton.icon(
                        onPressed: onValidateInstallation,
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Overiť inštaláciu'),
                      ),
                    if (onInstall != null)
                      FilledButton.icon(
                        onPressed: onInstall,
                        icon: const Icon(Icons.download_done_outlined),
                        label: const Text('Inštalovať z priečinka'),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
