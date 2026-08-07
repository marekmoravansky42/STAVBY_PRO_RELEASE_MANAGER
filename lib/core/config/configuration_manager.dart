import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'configuration_cache.dart';
import 'configuration_keys.dart';
import 'configuration_validator.dart';

class ConfigurationManager {
  ConfigurationManager._();

  static final ConfigurationManager instance = ConfigurationManager._();

  final ConfigurationCache _cache = ConfigurationCache();
  final ConfigurationValidator _validator = const ConfigurationValidator();

  File get configurationFile {
    final appData = Platform.environment['APPDATA'];
    final base = appData == null || appData.trim().isEmpty
        ? Directory.systemTemp.path
        : appData;
    return File(
      path.join(
        base,
        'STAVBY_PRO_RELEASE_MANAGER',
        'app_settings.json',
      ),
    );
  }

  Future<Map<String, dynamic>> load() {
    return _cache.load(_readAndValidate);
  }

  Future<Map<String, dynamic>> _readAndValidate() async {
    final file = configurationFile;
    if (!await file.exists()) {
      return _validator.validate(<String, dynamic>{}).configuration;
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      final raw = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
      final validation = _validator.validate(raw);
      if (validation.wasCorrected) {
        await _write(validation.configuration);
      }
      return validation.configuration;
    } catch (_) {
      return _validator.validate(<String, dynamic>{}).configuration;
    }
  }

  Future<T?> read<T>(String key) async {
    final data = await load();
    final value = data[key];
    return value is T ? value : null;
  }

  Future<void> write(String key, Object? value) async {
    final data = await load();
    if (value == null || (value is String && value.trim().isEmpty)) {
      data.remove(key);
    } else {
      data[key] = value is String ? value.trim() : value;
    }
    await save(data);
  }

  Future<void> remove(String key) async {
    final data = await load();
    data.remove(key);
    await save(data);
  }

  Future<void> save(Map<String, dynamic> configuration) async {
    final validation = _validator.validate(configuration);
    await _write(validation.configuration);
    _cache.replace(validation.configuration);
  }

  Future<void> _write(Map<String, dynamic> configuration) async {
    final file = configurationFile;
    await file.parent.create(recursive: true);
    final output = Map<String, dynamic>.from(configuration)
      ..[ConfigurationKeys.updatedAt] = DateTime.now().toIso8601String();
    await file.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(output)}\n',
      flush: true,
    );
  }

  void invalidate() {
    _cache.invalidate();
  }
}
