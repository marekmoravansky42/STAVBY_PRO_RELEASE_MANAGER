import 'dart:io';

import 'plugin_package.dart';
import 'plugin_package_installer.dart';
import 'plugin_package_repository.dart';
import 'plugin_package_result.dart';

class PluginPackageUpdater {
  const PluginPackageUpdater(this.repository);

  final PluginPackageRepository repository;

  Future<PluginPackageResult> update(PluginPackage package) async {
    await repository.ensureReady();
    final installed = repository.pluginDirectory(package.id);
    if (!await installed.exists()) {
      return PluginPackageResult.failed(
        message: 'Plugin ${package.id} nie je nainštalovaný.',
        pluginId: package.id,
      );
    }

    final backup = repository.backupDirectory(package.id, package.version);
    try {
      await PluginPackageInstaller.copyDirectory(installed, backup);
      await installed.delete(recursive: true);
      await PluginPackageInstaller.copyDirectory(
        Directory(package.sourceDirectory),
        installed,
      );
      return PluginPackageResult.ok(
        message: 'Plugin ${package.id} bol úspešne aktualizovaný.',
        pluginId: package.id,
        installedPath: installed.path,
        backupPath: backup.path,
      );
    } catch (error, stackTrace) {
      if (await installed.exists()) await installed.delete(recursive: true);
      if (await backup.exists()) {
        await PluginPackageInstaller.copyDirectory(backup, installed);
      }
      return PluginPackageResult.failed(
        message: 'Aktualizácia pluginu ${package.id} zlyhala; pôvodná verzia bola obnovená.',
        pluginId: package.id,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
