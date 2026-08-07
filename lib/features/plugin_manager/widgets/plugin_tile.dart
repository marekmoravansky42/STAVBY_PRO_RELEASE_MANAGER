import 'package:flutter/material.dart';

import '../../../core/plugin_discovery/plugin_discovery_report.dart';

class PluginTile extends StatelessWidget {
  const PluginTile({
    super.key,
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final PluginDiscoveryEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final manifest = entry.manifest;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        selected: selected,
        onTap: onTap,
        leading: const Icon(Icons.extension_outlined),
        title: Text(manifest.name),
        subtitle: Text(
          '${manifest.id} • ${manifest.version}\n${_statusLabel(entry.status)}',
        ),
        isThreeLine: true,
        trailing: Icon(
          entry.isAvailable ? Icons.check_circle_outline : Icons.info_outline,
        ),
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
