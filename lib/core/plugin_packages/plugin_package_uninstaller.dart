import 'dart:io';

import 'plugin_package_installer.dart';
import 'plugin_package_repository.dart';
import 'plugin_package_result.dart';

class PluginPackageUninstaller {
  const PluginPackageUninstaller(this.repository);

  final PluginPackageRepository repository;

  Future<PluginPackageResult> uninstall(
    String pluginId, {
    bool createBackup = true,
  }) async {
    final installed = repository.pluginDirectory(pluginId);
    if (!await installed.exists()) {
      return PluginPackageResult.failed(
        message: 'Plugin $pluginId nie je nainštalovaný.',
        pluginId: pluginId,
      );
    }

    Directory? backup;
    try {
      if (createBackup) {
        backup = repository.backupDirectory(pluginId, 'uninstall');
        await PluginPackageInstaller.copyDirectory(installed, backup);
      }
      await installed.delete(recursive: true);
      return PluginPackageResult.ok(
        message: 'Plugin $pluginId bol odinštalovaný.',
        pluginId: pluginId,
        backupPath: backup?.path,
      );
    } catch (error, stackTrace) {
      return PluginPackageResult.failed(
        message: 'Odinštalovanie pluginu $pluginId zlyhalo.',
        pluginId: pluginId,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
