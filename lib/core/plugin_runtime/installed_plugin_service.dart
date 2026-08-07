import 'dart:convert';
import 'dart:io';

import '../plugin_discovery/plugin_manifest_parser.dart';
import 'installed_plugin_record.dart';

class InstalledPluginService {
  const InstalledPluginService({
    this.parser = const PluginManifestParser(),
  });

  final PluginManifestParser parser;

  Future<List<InstalledPluginRecord>> load(Directory pluginsDirectory) async {
    if (!await pluginsDirectory.exists()) {
      return const <InstalledPluginRecord>[];
    }

    final records = <InstalledPluginRecord>[];
    await for (final entity in pluginsDirectory.list(followLinks: false)) {
      if (entity is! Directory) {
        continue;
      }

      final manifestFile = File(
        '${entity.path}${Platform.pathSeparator}plugin.json',
      );
      if (!await manifestFile.exists()) {
        continue;
      }

      try {
        final validation = parser.parse(await manifestFile.readAsString());
        final manifest = validation.value;
        if (!validation.isValid || manifest == null) {
          continue;
        }
        final stat = await manifestFile.stat();
        records.add(
          InstalledPluginRecord(
            manifest: manifest,
            directory: entity,
            manifestFile: manifestFile,
            modifiedAt: stat.modified,
          ),
        );
      } on FileSystemException {
        // Nečitateľný plugin sa v prehľade preskočí. Diagnostika ho zachytí
        // pri samostatnej validácii pluginového adresára.
      }
    }

    records.sort(
      (a, b) => a.manifest.name.toLowerCase().compareTo(
            b.manifest.name.toLowerCase(),
          ),
    );
    return List<InstalledPluginRecord>.unmodifiable(records);
  }

  Future<void> setEnabled(
    InstalledPluginRecord record, {
    required bool enabled,
  }) async {
    final decoded = jsonDecode(await record.manifestFile.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('plugin.json nemá platnú objektovú štruktúru.');
    }

    decoded['enabled'] = enabled;
    final temporaryFile = File('${record.manifestFile.path}.tmp');
    await temporaryFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(decoded),
      flush: true,
    );
    if (await record.manifestFile.exists()) {
      await record.manifestFile.delete();
    }
    await temporaryFile.rename(record.manifestFile.path);
  }
}
