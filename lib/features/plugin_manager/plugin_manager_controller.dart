import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/plugin_discovery/plugin_discovery_report.dart';
import '../../core/plugin_discovery/plugin_discovery_service.dart';
import 'plugin_manager_state.dart';

class PluginManagerController extends ChangeNotifier {
  PluginManagerController({
    required PluginDiscoveryService discoveryService,
    required Directory pluginsDirectory,
  })  : _discoveryService = discoveryService,
        _pluginsDirectory = pluginsDirectory;

  final PluginDiscoveryService _discoveryService;
  final Directory _pluginsDirectory;

  PluginManagerState _state = const PluginManagerState();
  PluginManagerState get state => _state;

  Future<void> load() async {
    if (_state.isLoading) {
      return;
    }

    _setState(
      _state.copyWith(
        status: PluginManagerLoadStatus.loading,
        errorMessage: '',
      ),
    );

    try {
      final report = await _discoveryService.discover(_pluginsDirectory);
      final List<PluginDiscoveryEntry> entries =
          List<PluginDiscoveryEntry>.unmodifiable(report.entries);
      final selectedId = _state.selectedPluginId;
      final selectionStillExists = selectedId != null &&
          entries.any((entry) => entry.manifest.id == selectedId);
      _setState(
        PluginManagerState(
          status: PluginManagerLoadStatus.loaded,
          entries: entries,
          selectedPluginId: selectionStillExists ? selectedId : null,
        ),
      );
    } on Object catch (error) {
      _setState(
        PluginManagerState(
          status: PluginManagerLoadStatus.failed,
          entries: _state.entries,
          selectedPluginId: _state.selectedPluginId,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> refresh() => load();

  void selectPlugin(String pluginId) {
    if (_state.selectedPluginId == pluginId) {
      return;
    }
    final exists =
        _state.entries.any((entry) => entry.manifest.id == pluginId);
    if (!exists) {
      return;
    }
    _setState(_state.copyWith(selectedPluginId: pluginId));
  }

  void clearSelection() {
    if (_state.selectedPluginId == null) {
      return;
    }
    _setState(_state.copyWith(clearSelection: true));
  }

  void _setState(PluginManagerState nextState) {
    _state = nextState;
    notifyListeners();
  }
}
