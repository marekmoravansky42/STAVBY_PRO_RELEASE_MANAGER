import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:stavby_pro_release_manager/core/plugin_packages/plugin_packages.dart';

void main() {
  late Directory workspace;
  late Directory source;
  late PluginPackageManager manager;

  setUp(() async {
    workspace = await Directory.systemTemp.createTemp('rm_plugin_packages_');
    source = Directory(p.join(workspace.path, 'source'));
    await source.create(recursive: true);
    await File(p.join(source.path, 'plugin.json')).writeAsString(
      jsonEncode(<String, dynamic>{
        'id': 'example.plugin',
        'name': 'Example Plugin',
        'version': '1.0.0',
        'apiVersion': '1.0.0',
        'permissions': <String>['diagnostics'],
      }),
    );
    await File(p.join(source.path, 'payload.txt')).writeAsString('v1');

    manager = PluginPackageManager(
      repository: PluginPackageRepository(
        pluginsDirectory: Directory(p.join(workspace.path, 'plugins')),
        backupsDirectory: Directory(p.join(workspace.path, 'backups')),
      ),
    );
  });

  tearDown(() async {
    if (await workspace.exists()) await workspace.delete(recursive: true);
  });

  test('installs a valid extracted package', () async {
    final result = await manager.installFromDirectory(source);

    expect(result.success, isTrue);
    expect(
      File(p.join(workspace.path, 'plugins', 'example.plugin', 'payload.txt'))
          .existsSync(),
      isTrue,
    );
  });

  test('rejects package without manifest', () async {
    await File(p.join(source.path, 'plugin.json')).delete();

    final result = await manager.installFromDirectory(source);

    expect(result.success, isFalse);
    expect(result.message, contains('plugin.json'));
  });

  test('updates with backup and uninstalls', () async {
    expect((await manager.installFromDirectory(source)).success, isTrue);
    await File(p.join(source.path, 'payload.txt')).writeAsString('v2');

    final update = await manager.updateFromDirectory(source);
    expect(update.success, isTrue);
    expect(update.backupPath, isNotNull);
    expect(
      File(p.join(workspace.path, 'plugins', 'example.plugin', 'payload.txt'))
          .readAsStringSync(),
      'v2',
    );

    final uninstall = await manager.uninstall('example.plugin');
    expect(uninstall.success, isTrue);
    expect(
      Directory(p.join(workspace.path, 'plugins', 'example.plugin')).existsSync(),
      isFalse,
    );
  });
}
