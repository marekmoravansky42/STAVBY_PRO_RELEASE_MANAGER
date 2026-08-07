import 'dart:io';

import 'plugin_directory_scanner.dart';
import 'plugin_discovery_report.dart';
import 'plugin_registry_bridge.dart';

class PluginDiscoveryService {
  const PluginDiscoveryService({
    required this.scanner,
    required this.registryBridge,
  });

  final PluginDirectoryScanner scanner;
  final PluginRegistryBridge registryBridge;

  Future<PluginDiscoveryReport> discover(Directory pluginsDirectory) async {
    final scanResult = await scanner.scan(pluginsDirectory);
    final entries = <PluginDiscoveryEntry>[];

    for (final manifest in scanResult.manifests) {
      if (!manifest.enabled) {
        entries.add(
          PluginDiscoveryEntry(
            manifest: manifest,
            status: PluginDiscoveryStatus.disabled,
            message: 'Plugin je vypnutý v manifeste.',
          ),
        );
        continue;
      }

      final plugin = registryBridge.resolve(manifest);
      if (plugin == null) {
        entries.add(
          PluginDiscoveryEntry(
            manifest: manifest,
            status: PluginDiscoveryStatus.missingCompiledPlugin,
            message: 'Plugin nie je skompilovaný ani registrovaný v aplikácii.',
          ),
        );
        continue;
      }

      final mismatchErrors = registryBridge.validateMatch(manifest, plugin);
      if (mismatchErrors.isNotEmpty) {
        entries.add(
          PluginDiscoveryEntry(
            manifest: manifest,
            status: PluginDiscoveryStatus.descriptorMismatch,
            message: mismatchErrors.join(' '),
          ),
        );
        continue;
      }

      entries.add(
        PluginDiscoveryEntry(
          manifest: manifest,
          status: PluginDiscoveryStatus.available,
        ),
      );
    }

    return PluginDiscoveryReport(
      entries: List<PluginDiscoveryEntry>.unmodifiable(entries),
      scanIssues: scanResult.issues,
    );
  }
}
