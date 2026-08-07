import 'dart:io';

import 'plugin_configuration_result.dart';
import 'plugin_configuration_schema.dart';
import 'plugin_configuration_storage.dart';
import 'plugin_configuration_validator.dart';

typedef PluginConfigurationMigration = Map<String, dynamic> Function(
  int fromVersion,
  Map<String, dynamic> values,
);

class PluginConfigurationManager {
  PluginConfigurationManager({
    required PluginConfigurationStorage storage,
    PluginConfigurationValidator validator = const PluginConfigurationValidator(),
  })  : _storage = storage,
        _validator = validator;

  final PluginConfigurationStorage _storage;
  final PluginConfigurationValidator _validator;

  Future<PluginConfigurationResult> load({
    required PluginConfigurationSchema schema,
    PluginConfigurationMigration? migrate,
  }) async {
    try {
      final stored = await _storage.load(schema.pluginId);
      var values = stored?.values ?? <String, dynamic>{};
      final storedVersion = stored?.schemaVersion ?? schema.version;

      if (stored != null && storedVersion != schema.version) {
        if (migrate == null) {
          return PluginConfigurationResult(
            pluginId: schema.pluginId,
            configuration: const <String, dynamic>{},
            schemaVersion: schema.version,
            errors: <String>[
              'Konfigurácia používa schému $storedVersion, očakáva sa ${schema.version}.',
            ],
          );
        }
        values = migrate(storedVersion, Map<String, dynamic>.from(values));
      }

      final result = _validator.validate(schema: schema, source: values);
      if (result.isValid &&
          (stored == null || storedVersion != schema.version || result.wasCorrected)) {
        await save(schema: schema, values: result.configuration);
      }
      return result;
    } on FormatException catch (error) {
      return PluginConfigurationResult(
        pluginId: schema.pluginId,
        configuration: const <String, dynamic>{},
        schemaVersion: schema.version,
        errors: <String>['Poškodený konfiguračný súbor: ${error.message}'],
      );
    } on FileSystemException catch (error) {
      return PluginConfigurationResult(
        pluginId: schema.pluginId,
        configuration: const <String, dynamic>{},
        schemaVersion: schema.version,
        errors: <String>['Konfiguráciu sa nepodarilo načítať: ${error.message}'],
      );
    }
  }

  Future<PluginConfigurationResult> save({
    required PluginConfigurationSchema schema,
    required Map<String, dynamic> values,
  }) async {
    final result = _validator.validate(schema: schema, source: values);
    if (result.isValid) {
      await _storage.save(
        pluginId: schema.pluginId,
        schemaVersion: schema.version,
        values: result.configuration,
      );
    }
    return result;
  }

  Future<void> reset(String pluginId) => _storage.delete(pluginId);
}
