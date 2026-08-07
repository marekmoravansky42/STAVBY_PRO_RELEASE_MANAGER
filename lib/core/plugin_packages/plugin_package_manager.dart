import 'dart:io';

import 'plugin_package_installer.dart';
import 'plugin_package_repository.dart';
import 'plugin_package_result.dart';
import 'plugin_package_uninstaller.dart';
import 'plugin_package_updater.dart';
import 'plugin_package_validator.dart';

/// High-level facade for safe package validation and filesystem operations.
class PluginPackageManager {
  PluginPackageManager({
    required PluginPackageRepository repository,
    PluginPackageValidator validator = const PluginPackageValidator(),
  })  : _validator = validator,
        _installer = PluginPackageInstaller(repository),
        _updater = PluginPackageUpdater(repository),
        _uninstaller = PluginPackageUninstaller(repository);

  final PluginPackageValidator _validator;
  final PluginPackageInstaller _installer;
  final PluginPackageUpdater _updater;
  final PluginPackageUninstaller _uninstaller;

  Future<PluginPackageResult> installFromDirectory(
    Directory packageDirectory,
  ) async {
    final validation = await _validator.validateDirectory(packageDirectory);
    if (!validation.isValid) {
      return PluginPackageResult.failed(
        message: validation.errors.join('\n'),
        pluginId: validation.package?.id,
      );
    }
    return _installer.install(validation.package!);
  }

  Future<PluginPackageResult> updateFromDirectory(
    Directory packageDirectory,
  ) async {
    final validation = await _validator.validateDirectory(packageDirectory);
    if (!validation.isValid) {
      return PluginPackageResult.failed(
        message: validation.errors.join('\n'),
        pluginId: validation.package?.id,
      );
    }
    return _updater.update(validation.package!);
  }

  Future<PluginPackageResult> uninstall(
    String pluginId, {
    bool createBackup = true,
  }) =>
      _uninstaller.uninstall(pluginId, createBackup: createBackup);
}
