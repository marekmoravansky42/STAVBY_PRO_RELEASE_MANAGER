import 'package:flutter/material.dart';

import '../../core/plugin_configuration/plugin_configuration_manager.dart';
import '../../core/plugin_configuration/plugin_configuration_schema.dart';
import '../../core/plugin_discovery/plugin_discovery_report.dart';
import 'plugin_configuration_dialog.dart';
import 'plugin_permissions_dialog.dart';

class PluginDetailsPanel extends StatelessWidget {
  const PluginDetailsPanel({
    super.key,
    required this.entry,
    required this.onClose,
    this.configurationManager,
    this.configurationSchema,
  });

  final PluginDiscoveryEntry entry;
  final VoidCallback onClose;
  final PluginConfigurationManager? configurationManager;
  final PluginConfigurationSchema? configurationSchema;

  @override
  Widget build(BuildContext context) {
    final manifest = entry.manifest;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            children: [
              const Icon(Icons.extension_outlined, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manifest.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(manifest.id),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Zavrieť detail',
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _DetailRow(label: 'Verzia', value: manifest.version),
          _DetailRow(label: 'API verzia', value: manifest.apiVersion),
          _DetailRow(label: 'Stav', value: _statusLabel(entry.status)),
          _DetailRow(
            label: 'Povolený',
            value: manifest.enabled ? 'Áno' : 'Nie',
          ),
          if (configurationManager != null && configurationSchema != null) ...[
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => PluginConfigurationDialog.show(
                  context,
                  manager: configurationManager!,
                  schema: configurationSchema!,
                  pluginName: manifest.name,
                ),
                icon: const Icon(Icons.tune),
                label: const Text('Konfigurácia'),
              ),
            ),
          ],
          if (manifest.description.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Popis', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(manifest.description),
          ],
          if (entry.message.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Diagnostika', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(entry.message),
          ],
          if (manifest.capabilities.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Schopnosti', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: manifest.capabilities
                  .map((value) => Chip(label: Text(value)))
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 18),
          Text('Oprávnenia', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            manifest.permissions.isEmpty
                ? 'Plugin nepožaduje žiadne osobitné oprávnenia.'
                : 'Počet požadovaných oprávnení: ${manifest.permissions.length}',
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => PluginPermissionsDialog.show(
                context,
                pluginName: manifest.name,
                permissionNames: manifest.permissions,
              ),
              icon: const Icon(Icons.security_outlined),
              label: const Text('Zobraziť oprávnenia'),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(PluginDiscoveryStatus status) {
    switch (status) {
      case PluginDiscoveryStatus.available:
        return 'Dostupný';
      case PluginDiscoveryStatus.disabled:
        return 'Vypnutý';
      case PluginDiscoveryStatus.missingCompiledPlugin:
        return 'Chýba skompilovaný plugin';
      case PluginDiscoveryStatus.descriptorMismatch:
        return 'Nesúlad manifestu';
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
