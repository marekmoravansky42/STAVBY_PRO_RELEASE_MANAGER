import 'dart:io';

import 'package:path/path.dart' as p;

import 'plugin_package.dart';
import 'plugin_package_repository.dart';
import 'plugin_package_result.dart';

class PluginPackageInstaller {
  const PluginPackageInstaller(this.repository);

  final PluginPackageRepository repository;

  Future<PluginPackageResult> install(
    PluginPackage package, {
    bool overwrite = false,
  }) async {
    await repository.ensureReady();
    final target = repository.pluginDirectory(package.id);
    if (await target.exists() && !overwrite) {
      return PluginPackageResult.failed(
        message: 'Plugin ${package.id} je už nainštalovaný.',
        pluginId: package.id,
      );
    }

    try {
      if (await target.exists()) await target.delete(recursive: true);
      await _copyDirectory(Directory(package.sourceDirectory), target);
      return PluginPackageResult.ok(
        message: 'Plugin ${package.id} bol úspešne nainštalovaný.',
        pluginId: package.id,
        installedPath: target.path,
      );
    } catch (error, stackTrace) {
      if (await target.exists()) await target.delete(recursive: true);
      return PluginPackageResult.failed(
        message: 'Inštalácia pluginu ${package.id} zlyhala.',
        pluginId: package.id,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> copyDirectory(Directory source, Directory target) =>
      _copyDirectory(source, target);

  static Future<void> _copyDirectory(
    Directory source,
    Directory target,
  ) async {
    await target.create(recursive: true);
    await for (final entity in source.list(followLinks: false)) {
      final destination = p.join(target.path, p.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(destination));
      } else if (entity is File) {
        await entity.copy(destination);
      } else if (entity is Link) {
        throw FileSystemException(
          'Symbolické odkazy nie sú v pluginovom balíku povolené.',
          entity.path,
        );
      }
    }
  }
}
