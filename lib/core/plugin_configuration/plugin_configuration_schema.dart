enum PluginConfigurationValueType {
  string,
  integer,
  decimal,
  boolean,
  list,
  map,
}

class PluginConfigurationField {
  const PluginConfigurationField({
    required this.key,
    required this.type,
    this.required = false,
    this.defaultValue,
  });

  final String key;
  final PluginConfigurationValueType type;
  final bool required;
  final Object? defaultValue;

  bool accepts(Object? value) {
    if (value == null) return !required;
    return switch (type) {
      PluginConfigurationValueType.string => value is String,
      PluginConfigurationValueType.integer => value is int,
      PluginConfigurationValueType.decimal => value is num,
      PluginConfigurationValueType.boolean => value is bool,
      PluginConfigurationValueType.list => value is List,
      PluginConfigurationValueType.map => value is Map,
    };
  }
}

class PluginConfigurationSchema {
  PluginConfigurationSchema({
    required this.pluginId,
    required this.version,
    required Iterable<PluginConfigurationField> fields,
    this.allowUnknownKeys = false,
  }) : fields = Map<String, PluginConfigurationField>.unmodifiable(
          <String, PluginConfigurationField>{
            for (final field in fields) field.key: field,
          },
        ) {
    if (pluginId.trim().isEmpty) {
      throw ArgumentError.value(pluginId, 'pluginId', 'Plugin ID nesmie byť prázdne.');
    }
    if (version < 1) {
      throw ArgumentError.value(version, 'version', 'Verzia schémy musí byť aspoň 1.');
    }
    if (this.fields.keys.any((key) => key.trim().isEmpty)) {
      throw ArgumentError('Kľúč konfiguračného poľa nesmie byť prázdny.');
    }
  }

  final String pluginId;
  final int version;
  final Map<String, PluginConfigurationField> fields;
  final bool allowUnknownKeys;
}
