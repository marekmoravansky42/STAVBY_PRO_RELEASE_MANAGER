import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/core/plugin_discovery/plugin_discovery.dart';
import 'package:stavby_pro_release_manager/core/plugin_sdk/plugin_sdk.dart';

class _TestPlugin implements PluginApi {
  @override
  PluginDescriptor get descriptor => const PluginDescriptor(
        id: 'test.plugin',
        name: 'Test Plugin',
        version: '1.0.0',
        minimumHostVersion: '6.3.0',
        capabilities: <PluginCapability>{PluginCapability.diagnosticsProvider},
      );

  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize(PluginContext context) async {}
}

void main() {
  test('discovers a matching compiled plugin', () async {
    final directory = await Directory.systemTemp.createTemp('plugin_discovery_');
    addTearDown(() => directory.delete(recursive: true));

    final pluginDirectory = Directory('${directory.path}/test_plugin');
    await pluginDirectory.create(recursive: true);
    await File('${pluginDirectory.path}/plugin.json').writeAsString('''
{
  "id": "test.plugin",
  "name": "Test Plugin",
  "version": "1.0.0",
  "apiVersion": "1.0.0",
  "enabled": true
}
''');

    final registry = PluginRegistry()..register(_TestPlugin());
    final service = PluginDiscoveryService(
      scanner: const PluginDirectoryScanner(),
      registryBridge: PluginRegistryBridge(registry),
    );

    final report = await service.discover(directory);

    expect(report.scanIssues, isEmpty);
    expect(report.entries, hasLength(1));
    expect(report.entries.single.status, PluginDiscoveryStatus.available);
  });
}
