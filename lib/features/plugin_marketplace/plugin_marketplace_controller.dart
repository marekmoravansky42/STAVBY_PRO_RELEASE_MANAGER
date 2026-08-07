import 'package:flutter/foundation.dart';

import '../../core/plugin_marketplace/plugin_marketplace_manifest.dart';
import '../../core/plugin_marketplace/plugin_marketplace_repository.dart';
import 'plugin_marketplace_state.dart';

class PluginMarketplaceController extends ChangeNotifier {
  PluginMarketplaceController({
    required PluginMarketplaceRepository repository,
    required Uri indexUri,
  })  : _repository = repository,
        _indexUri = indexUri;

  final PluginMarketplaceRepository _repository;
  final Uri _indexUri;

  PluginMarketplaceState _state = const PluginMarketplaceState();
  PluginMarketplaceState get state => _state;

  Future<void> load() async {
    if (_state.isLoading) {
      return;
    }
    _setState(
      _state.copyWith(
        status: PluginMarketplaceLoadStatus.loading,
        message: '',
      ),
    );

    final result = await _repository.refresh(_indexUri);
    final index = result.value;
    if (!result.success || index == null) {
      _setState(
        _state.copyWith(
          status: PluginMarketplaceLoadStatus.failed,
          message: result.message,
          fromCache: result.fromCache,
        ),
      );
      return;
    }

    final plugins = List<PluginMarketplaceManifest>.unmodifiable(index.plugins);
    final categories = plugins
        .expand((plugin) => plugin.categories)
        .map((category) => category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    _state = PluginMarketplaceState(
      status: PluginMarketplaceLoadStatus.loaded,
      plugins: plugins,
      filteredPlugins: plugins,
      categories: List<String>.unmodifiable(categories),
      message: result.message,
      fromCache: result.fromCache,
    );
    _applyFilters(notify: false);
    notifyListeners();
  }

  Future<void> refresh() => load();

  void setQuery(String value) {
    if (_state.query == value) {
      return;
    }
    _state = _state.copyWith(query: value);
    _applyFilters();
  }

  void setCategory(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      if (_state.selectedCategory == null) {
        return;
      }
      _state = _state.copyWith(clearSelectedCategory: true);
    } else {
      if (_state.selectedCategory == normalized) {
        return;
      }
      _state = _state.copyWith(selectedCategory: normalized);
    }
    _applyFilters();
  }

  void clearFilters() {
    if (_state.query.isEmpty && _state.selectedCategory == null) {
      return;
    }
    _state = _state.copyWith(query: '', clearSelectedCategory: true);
    _applyFilters();
  }

  void _applyFilters({bool notify = true}) {
    final plugins = _state.plugins.where((plugin) {
      final query = _state.query.trim().toLowerCase();
      final queryMatches = query.isEmpty ||
          plugin.id.toLowerCase().contains(query) ||
          plugin.name.toLowerCase().contains(query) ||
          plugin.author.toLowerCase().contains(query) ||
          plugin.description.toLowerCase().contains(query);
      final category = _state.selectedCategory?.toLowerCase();
      final categoryMatches = category == null ||
          plugin.categories.any((item) => item.toLowerCase() == category);
      return queryMatches && categoryMatches;
    }).toList(growable: false)
      ..sort((a, b) {
        final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return byName != 0 ? byName : a.id.compareTo(b.id);
      });

    _state = _state.copyWith(
      filteredPlugins: List<PluginMarketplaceManifest>.unmodifiable(plugins),
    );
    if (notify) {
      notifyListeners();
    }
  }

  void _setState(PluginMarketplaceState value) {
    _state = value;
    notifyListeners();
  }
}
