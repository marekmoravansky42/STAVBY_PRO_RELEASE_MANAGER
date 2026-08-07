import 'plugin_configuration_schema.dart';

class PluginConfigurationDefaults {
  const PluginConfigurationDefaults._();

  static Map<String, dynamic> fromSchema(PluginConfigurationSchema schema) {
    return <String, dynamic>{
      for (final entry in schema.fields.entries)
        if (entry.value.defaultValue != null)
          entry.key: _copyValue(entry.value.defaultValue),
    };
  }

  static Object? _copyValue(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List) return List<dynamic>.from(value);
    return value;
  }
}
