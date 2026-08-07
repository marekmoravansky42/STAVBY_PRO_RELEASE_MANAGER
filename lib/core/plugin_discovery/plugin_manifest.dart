/// Serializable metadata read from a plugin.json file.
class PluginManifest {
  const PluginManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.apiVersion,
    this.enabled = true,
    this.description = '',
    this.entryPoint = '',
    this.capabilities = const <String>[],
    this.permissions = const <String>[],
  });

  final String id;
  final String name;
  final String version;
  final String apiVersion;
  final bool enabled;
  final String description;
  final String entryPoint;
  final List<String> capabilities;
  final List<String> permissions;

  factory PluginManifest.fromJson(Map<String, dynamic> json) {
    return PluginManifest(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      apiVersion: json['apiVersion'] as String,
      enabled: json['enabled'] as bool? ?? true,
      description: json['description'] as String? ?? '',
      entryPoint: json['entryPoint'] as String? ?? '',
      capabilities: List<String>.unmodifiable(
        (json['capabilities'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic value) => value as String),
      ),
      permissions: List<String>.unmodifiable(
        (json['permissions'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic value) => value as String),
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'version': version,
        'apiVersion': apiVersion,
        'enabled': enabled,
        if (description.isNotEmpty) 'description': description,
        if (entryPoint.isNotEmpty) 'entryPoint': entryPoint,
        if (capabilities.isNotEmpty) 'capabilities': capabilities,
        if (permissions.isNotEmpty) 'permissions': permissions,
      };
}
