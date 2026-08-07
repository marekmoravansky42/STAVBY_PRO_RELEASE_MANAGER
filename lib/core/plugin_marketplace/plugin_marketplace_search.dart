import 'plugin_marketplace_index.dart';
import 'plugin_marketplace_manifest.dart';

/// Deterministic local search over a marketplace index.
class PluginMarketplaceSearch {
  const PluginMarketplaceSearch();

  List<PluginMarketplaceManifest> search(
    PluginMarketplaceIndex index, {
    String query = '',
    String? author,
    String? category,
    String? apiVersion,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedAuthor = author?.trim().toLowerCase();
    final normalizedCategory = category?.trim().toLowerCase();

    final matches = index.plugins.where((plugin) {
      final textMatches = normalizedQuery.isEmpty ||
          plugin.id.toLowerCase().contains(normalizedQuery) ||
          plugin.name.toLowerCase().contains(normalizedQuery) ||
          plugin.description.toLowerCase().contains(normalizedQuery) ||
          plugin.author.toLowerCase().contains(normalizedQuery);
      final authorMatches = normalizedAuthor == null ||
          plugin.author.toLowerCase() == normalizedAuthor;
      final categoryMatches = normalizedCategory == null ||
          plugin.categories.any(
            (value) => value.toLowerCase() == normalizedCategory,
          );
      final apiMatches = apiVersion == null || plugin.apiVersion == apiVersion;
      return textMatches && authorMatches && categoryMatches && apiMatches;
    }).toList(growable: false)
      ..sort((a, b) {
        final name = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return name != 0 ? name : a.id.compareTo(b.id);
      });
    return List<PluginMarketplaceManifest>.unmodifiable(matches);
  }
}
