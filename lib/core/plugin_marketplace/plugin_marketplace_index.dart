import 'plugin_marketplace_manifest.dart';

/// Immutable marketplace catalogue.
class PluginMarketplaceIndex {
  const PluginMarketplaceIndex({
    required this.schemaVersion,
    required this.generatedAt,
    required this.plugins,
  });

  final int schemaVersion;
  final DateTime generatedAt;
  final List<PluginMarketplaceManifest> plugins;

  factory PluginMarketplaceIndex.fromJson(Map<String, dynamic> json) {
    return PluginMarketplaceIndex(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      generatedAt: DateTime.parse(json['generatedAt'] as String).toUtc(),
      plugins: List<PluginMarketplaceManifest>.unmodifiable(
        (json['plugins'] as List<dynamic>? ?? const <dynamic>[]).map(
          (dynamic value) => PluginMarketplaceManifest.fromJson(
            value as Map<String, dynamic>,
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'schemaVersion': schemaVersion,
        'generatedAt': generatedAt.toUtc().toIso8601String(),
        'plugins': plugins
            .map((PluginMarketplaceManifest item) => item.toJson())
            .toList(growable: false),
      };
}
