import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/core/plugin_runtime/plugin_runtime.dart';

void main() {
  test('loads an installed plugin and updates enabled state', () async {
    final root = await Directory.systemTemp.createTemp('rm_installed_plugins_');
    addTearDown(() => root.delete(recursive: true));

    final pluginDir = Directory('${root.path}${Platform.pathSeparator}demo');
    await pluginDir.create(recursive: true);
    final manifest = File('${pluginDir.path}${Platform.pathSeparator}plugin.json');
    await manifest.writeAsString('''
{
  "id": "demo.plugin",
  "name": "Demo Plugin",
  "version": "1.0.0",
  "apiVersion": "1.0.0",
  "enabled": true
}
''');

    const service = InstalledPluginService();
    var plugins = await service.load(root);
    expect(plugins, hasLength(1));
    expect(plugins.single.enabled, isTrue);

    await service.setEnabled(plugins.single, enabled: false);
    plugins = await service.load(root);
    expect(plugins.single.enabled, isFalse);
  });
}
