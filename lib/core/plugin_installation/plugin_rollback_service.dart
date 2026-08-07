import 'dart:io';

import 'package:path/path.dart' as p;

import '../plugin_packages/plugin_package_installer.dart';
import '../plugin_packages/plugin_package_repository.dart';
import '../plugin_packages/plugin_package_result.dart';

/// Creates and restores filesystem snapshots for installed plugins.
class PluginRollbackService {
  const PluginRollbackService(this.repository);

  final PluginPackageRepository repository;

  Future<Directory?> createBackup(
    String pluginId, {
    required String version,
  }) async {
    await repository.ensureReady();
    final installed = repository.pluginDirectory(pluginId);
    if (!await installed.exists()) {
      return null;
    }

    final backup = repository.backupDirectory(pluginId, version);
    await PluginPackageInstaller.copyDirectory(installed, backup);
    return backup;
  }

  Future<PluginPackageResult> restoreBackup(
    String pluginId,
    Directory backup,
  ) async {
    await repository.ensureReady();
    if (!await backup.exists()) {
      return PluginPackageResult.failed(
        message: 'Záloha pluginu $pluginId neexistuje.',
        pluginId: pluginId,
      );
    }

    final target = repository.pluginDirectory(pluginId);
    try {
      if (await target.exists()) {
        await target.delete(recursive: true);
      }
      await PluginPackageInstaller.copyDirectory(backup, target);
      return PluginPackageResult.ok(
        message: 'Plugin $pluginId bol úspešne obnovený zo zálohy.',
        pluginId: pluginId,
        installedPath: target.path,
        backupPath: backup.path,
      );
    } catch (error, stackTrace) {
      return PluginPackageResult.failed(
        message: 'Obnovenie pluginu $pluginId zo zálohy zlyhalo.',
        pluginId: pluginId,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<List<Directory>> listBackups(String pluginId) async {
    final root = Directory(p.join(repository.backupsDirectory.path, pluginId));
    if (!await root.exists()) {
      return const <Directory>[];
    }

    final backups = <Directory>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is Directory) {
        backups.add(entity);
      }
    }
    backups.sort((a, b) => b.path.compareTo(a.path));
    return backups;
  }

  Future<PluginPackageResult> rollbackLatest(String pluginId) async {
    final backups = await listBackups(pluginId);
    if (backups.isEmpty) {
      return PluginPackageResult.failed(
        message: 'Pre plugin $pluginId nebola nájdená žiadna záloha.',
        pluginId: pluginId,
      );
    }
    return restoreBackup(pluginId, backups.first);
  }
}
