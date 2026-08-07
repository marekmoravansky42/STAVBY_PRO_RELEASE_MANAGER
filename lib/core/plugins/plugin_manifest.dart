import 'dart:convert';

/// Declarative metadata used by the plugin registry.
///
/// Build 212 intentionally registers manifest-based project extensions only.
/// Executable Dart code is still compiled with the application and is not
/// loaded dynamically from disk.
class PluginManifest {
  const PluginManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.minimumReleaseManagerVersion,
    required this.platforms,
    this.description = '',
    this.profileId,
    this.enabled = true,
  });

  final String id;
  final String name;
  final String version;
  final String minimumReleaseManagerVersion;
  final List<String> platforms;
  final String description;
  final String? profileId;
  final bool enabled;

  factory PluginManifest.fromJson(Map<String, Object?> json) {
    final rawPlatforms = json['platforms'];
    if (rawPlatforms is! List<Object?>) {
      throw const FormatException('Plugin manifest nemá zoznam platforiem.');
    }

    return PluginManifest(
      id: (json['id'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
      version: (json['version'] as String? ?? '').trim(),
      minimumReleaseManagerVersion:
          (json['minimumReleaseManagerVersion'] as String? ?? '').trim(),
      platforms: List<String>.unmodifiable(
        rawPlatforms.map((value) => value.toString().trim().toLowerCase()),
      ),
      description: (json['description'] as String? ?? '').trim(),
      profileId: (json['profileId'] as String?)?.trim(),
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'version': version,
        'minimumReleaseManagerVersion': minimumReleaseManagerVersion,
        'platforms': platforms,
        'description': description,
        if (profileId != null && profileId!.isNotEmpty) 'profileId': profileId,
        'enabled': enabled,
      };

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());
}
