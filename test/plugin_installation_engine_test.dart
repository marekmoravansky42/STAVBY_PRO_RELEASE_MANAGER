import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:stavby_pro_release_manager/core/plugin_installation/plugin_installation.dart';

void main() {
  test('installs a valid extracted plugin package', () async {
    final root = await Directory.systemTemp.createTemp('rm_plugin_install_');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    final source = Directory(p.join(root.path, 'source'))..createSync();
    File(p.join(source.path, 'plugin.json')).writeAsStringSync(
      jsonEncode(<String, Object>{
        'id': 'demo.plugin',
        'name': 'Demo plugin',
        'version': '1.0.0',
        'apiVersion': '1.0.0',
        'enabled': true,
      }),
    );
    File(p.join(source.path, 'README.md')).writeAsStringSync('demo');

    final engine = PluginInstallationEngine(
      pluginsDirectory: Directory(p.join(root.path, 'plugins')),
      backupsDirectory: Directory(p.join(root.path, 'backups')),
    );
    final result = await engine.installFromDirectory(
      source,
      expectedPluginId: 'demo.plugin',
    );

    expect(result.success, isTrue);
    expect(
      File(p.join(root.path, 'plugins', 'demo.plugin', 'plugin.json')).existsSync(),
      isTrue,
    );
  });

  test('rejects a package with a different plugin id', () async {
    final root = await Directory.systemTemp.createTemp('rm_plugin_reject_');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    final source = Directory(p.join(root.path, 'source'))..createSync();
    File(p.join(source.path, 'plugin.json')).writeAsStringSync(
      jsonEncode(<String, Object>{
        'id': 'other.plugin',
        'name': 'Other plugin',
        'version': '1.0.0',
        'apiVersion': '1.0.0',
      }),
    );

    final engine = PluginInstallationEngine(
      pluginsDirectory: Directory(p.join(root.path, 'plugins')),
      backupsDirectory: Directory(p.join(root.path, 'backups')),
    );
    final result = await engine.installFromDirectory(
      source,
      expectedPluginId: 'demo.plugin',
    );

    expect(result.success, isFalse);
    expect(Directory(p.join(root.path, 'plugins', 'other.plugin')).existsSync(), isFalse);
  });
}
