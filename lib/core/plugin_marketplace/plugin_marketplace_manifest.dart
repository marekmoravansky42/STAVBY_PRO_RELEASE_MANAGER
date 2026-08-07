/// Metadata for a plugin version published in a marketplace index.
class PluginMarketplaceManifest {
  const PluginMarketplaceManifest({
    required this.id,
    required this.name,
    required this.author,
    required this.version,
    required this.apiVersion,
    required this.minimumReleaseManagerVersion,
    required this.downloadUrl,
    required this.sha256,
    this.description = '',
    this.categories = const <String>[],
    this.signature = '',
  });

  final String id;
  final String name;
  final String author;
  final String version;
  final String apiVersion;
  final String minimumReleaseManagerVersion;
  final String downloadUrl;
  final String sha256;
  final String description;
  final List<String> categories;
  final String signature;

  factory PluginMarketplaceManifest.fromJson(Map<String, dynamic> json) {
    return PluginMarketplaceManifest(
      id: json['id'] as String,
      name: json['name'] as String,
      author: json['author'] as String,
      version: json['version'] as String,
      apiVersion: json['apiVersion'] as String,
      minimumReleaseManagerVersion:
          json['minimumReleaseManagerVersion'] as String,
      downloadUrl: json['downloadUrl'] as String,
      sha256: json['sha256'] as String,
      description: json['description'] as String? ?? '',
      categories: List<String>.unmodifiable(
        (json['categories'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic value) => value as String),
      ),
      signature: json['signature'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'author': author,
        'version': version,
        'apiVersion': apiVersion,
        'minimumReleaseManagerVersion': minimumReleaseManagerVersion,
        'downloadUrl': downloadUrl,
        'sha256': sha256,
        if (description.isNotEmpty) 'description': description,
        if (categories.isNotEmpty) 'categories': categories,
        if (signature.isNotEmpty) 'signature': signature,
      };
}
