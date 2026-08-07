import 'dart:io';

import 'package:path/path.dart' as p;

/// Resolves installation and backup locations for plugin packages.
class PluginPackageRepository {
  const PluginPackageRepository({
    required this.pluginsDirectory,
    required this.backupsDirectory,
  });

  final Directory pluginsDirectory;
  final Directory backupsDirectory;

  Directory pluginDirectory(String pluginId) =>
      Directory(p.join(pluginsDirectory.path, pluginId));

  Directory backupDirectory(String pluginId, String version) => Directory(
        p.join(
          backupsDirectory.path,
          pluginId,
          '${DateTime.now().microsecondsSinceEpoch}_$version',
        ),
      );

  Future<void> ensureReady() async {
    await pluginsDirectory.create(recursive: true);
    await backupsDirectory.create(recursive: true);
  }
}
