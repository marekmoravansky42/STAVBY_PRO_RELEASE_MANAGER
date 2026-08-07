import '../../core/plugin_marketplace/plugin_marketplace_manifest.dart';

enum PluginMarketplaceLoadStatus { initial, loading, loaded, failed }

class PluginMarketplaceState {
  const PluginMarketplaceState({
    this.status = PluginMarketplaceLoadStatus.initial,
    this.plugins = const <PluginMarketplaceManifest>[],
    this.filteredPlugins = const <PluginMarketplaceManifest>[],
    this.categories = const <String>[],
    this.query = '',
    this.selectedCategory,
    this.message = '',
    this.fromCache = false,
  });

  final PluginMarketplaceLoadStatus status;
  final List<PluginMarketplaceManifest> plugins;
  final List<PluginMarketplaceManifest> filteredPlugins;
  final List<String> categories;
  final String query;
  final String? selectedCategory;
  final String message;
  final bool fromCache;

  bool get isLoading => status == PluginMarketplaceLoadStatus.loading;
  bool get hasError => status == PluginMarketplaceLoadStatus.failed;

  PluginMarketplaceState copyWith({
    PluginMarketplaceLoadStatus? status,
    List<PluginMarketplaceManifest>? plugins,
    List<PluginMarketplaceManifest>? filteredPlugins,
    List<String>? categories,
    String? query,
    String? selectedCategory,
    bool clearSelectedCategory = false,
    String? message,
    bool? fromCache,
  }) {
    return PluginMarketplaceState(
      status: status ?? this.status,
      plugins: plugins ?? this.plugins,
      filteredPlugins: filteredPlugins ?? this.filteredPlugins,
      categories: categories ?? this.categories,
      query: query ?? this.query,
      selectedCategory:
          clearSelectedCategory ? null : selectedCategory ?? this.selectedCategory,
      message: message ?? this.message,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}
