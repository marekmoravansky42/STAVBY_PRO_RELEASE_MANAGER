import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:stavby_pro_release_manager/core/plugin_installation/plugin_installation.dart';
import 'package:stavby_pro_release_manager/core/plugin_packages/plugin_package_repository.dart';

void main() {
  test('creates and restores the latest plugin backup', () async {
    final root = await Directory.systemTemp.createTemp('rm_plugin_rollback_');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    final repository = PluginPackageRepository(
      pluginsDirectory: Directory(p.join(root.path, 'plugins')),
      backupsDirectory: Directory(p.join(root.path, 'backups')),
    );
    final installed = repository.pluginDirectory('demo.plugin');
    await installed.create(recursive: true);
    final dataFile = File(p.join(installed.path, 'data.txt'));
    await dataFile.writeAsString('original');

    final rollback = PluginRollbackService(repository);
    final backup = await rollback.createBackup(
      'demo.plugin',
      version: '1.0.0',
    );
    expect(backup, isNotNull);

    await dataFile.writeAsString('changed');
    final result = await rollback.rollbackLatest('demo.plugin');

    expect(result.success, isTrue);
    expect(await dataFile.readAsString(), 'original');
  });
}
