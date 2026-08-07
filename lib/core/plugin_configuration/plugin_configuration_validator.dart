import 'plugin_configuration_defaults.dart';
import 'plugin_configuration_result.dart';
import 'plugin_configuration_schema.dart';

class PluginConfigurationValidator {
  const PluginConfigurationValidator();

  PluginConfigurationResult validate({
    required PluginConfigurationSchema schema,
    required Map<String, dynamic> source,
  }) {
    final output = PluginConfigurationDefaults.fromSchema(schema);
    final errors = <String>[];
    final corrections = <String>[];

    for (final entry in source.entries) {
      final field = schema.fields[entry.key];
      if (field == null) {
        if (schema.allowUnknownKeys) {
          output[entry.key] = entry.value;
        } else {
          corrections.add('${entry.key}: neznámy kľúč bol odstránený');
        }
        continue;
      }

      if (!field.accepts(entry.value)) {
        errors.add('${entry.key}: neplatný typ hodnoty');
        continue;
      }
      output[entry.key] = entry.value;
    }

    for (final field in schema.fields.values) {
      if (field.required && !output.containsKey(field.key)) {
        errors.add('${field.key}: povinná hodnota chýba');
      }
    }

    return PluginConfigurationResult(
      pluginId: schema.pluginId,
      configuration: Map<String, dynamic>.unmodifiable(output),
      schemaVersion: schema.version,
      errors: List<String>.unmodifiable(errors),
      corrections: List<String>.unmodifiable(corrections),
    );
  }
}
