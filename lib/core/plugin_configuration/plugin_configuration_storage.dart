import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class StoredPluginConfiguration {
  const StoredPluginConfiguration({
    required this.schemaVersion,
    required this.values,
  });

  final int schemaVersion;
  final Map<String, dynamic> values;
}

class PluginConfigurationStorage {
  PluginConfigurationStorage({required Directory rootDirectory})
      : _rootDirectory = rootDirectory;

  final Directory _rootDirectory;

  Future<StoredPluginConfiguration?> load(String pluginId) async {
    final file = _fileFor(pluginId);
    if (!await file.exists()) return null;

    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Konfigurácia pluginu musí byť JSON objekt.');
    }
    final version = decoded['schemaVersion'];
    final values = decoded['values'];
    if (version is! int || values is! Map<String, dynamic>) {
      throw const FormatException('Konfigurácia pluginu má neplatnú štruktúru.');
    }
    return StoredPluginConfiguration(
      schemaVersion: version,
      values: Map<String, dynamic>.from(values),
    );
  }

  Future<void> save({
    required String pluginId,
    required int schemaVersion,
    required Map<String, dynamic> values,
  }) async {
    await _rootDirectory.create(recursive: true);
    final file = _fileFor(pluginId);
    final temporary = File('${file.path}.tmp');
    final payload = <String, dynamic>{
      'pluginId': pluginId,
      'schemaVersion': schemaVersion,
      'values': values,
    };
    await temporary.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  Future<void> delete(String pluginId) async {
    final file = _fileFor(pluginId);
    if (await file.exists()) await file.delete();
  }

  File _fileFor(String pluginId) {
    final safeId = pluginId.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return File(p.join(_rootDirectory.path, '$safeId.json'));
  }
}
