class PluginConfigurationResult {
  const PluginConfigurationResult({
    required this.pluginId,
    required this.configuration,
    required this.schemaVersion,
    this.errors = const <String>[],
    this.corrections = const <String>[],
  });

  final String pluginId;
  final Map<String, dynamic> configuration;
  final int schemaVersion;
  final List<String> errors;
  final List<String> corrections;

  bool get isValid => errors.isEmpty;
  bool get wasCorrected => corrections.isNotEmpty;
}
