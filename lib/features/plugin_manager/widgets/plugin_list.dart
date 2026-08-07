import 'package:flutter/material.dart';

import '../../../core/plugin_discovery/plugin_discovery_report.dart';
import 'plugin_tile.dart';

class PluginList extends StatelessWidget {
  const PluginList({
    super.key,
    required this.entries,
    required this.selectedPluginId,
    required this.onSelected,
  });

  final List<PluginDiscoveryEntry> entries;
  final String? selectedPluginId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return PluginTile(
          entry: entry,
          selected: entry.manifest.id == selectedPluginId,
          onTap: () => onSelected(entry.manifest.id),
        );
      },
    );
  }
}
