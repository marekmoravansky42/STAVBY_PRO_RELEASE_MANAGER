import '../../core/plugin_discovery/plugin_discovery_report.dart';

enum PluginManagerLoadStatus { initial, loading, loaded, failed }

class PluginManagerState {
  const PluginManagerState({
    this.status = PluginManagerLoadStatus.initial,
    this.entries = const <PluginDiscoveryEntry>[],
    this.selectedPluginId,
    this.errorMessage = '',
  });

  final PluginManagerLoadStatus status;
  final List<PluginDiscoveryEntry> entries;
  final String? selectedPluginId;
  final String errorMessage;

  bool get isLoading => status == PluginManagerLoadStatus.loading;
  bool get hasError => status == PluginManagerLoadStatus.failed;

  PluginDiscoveryEntry? get selectedEntry {
    final id = selectedPluginId;
    if (id == null) {
      return null;
    }
    for (final entry in entries) {
      if (entry.manifest.id == id) {
        return entry;
      }
    }
    return null;
  }

  PluginManagerState copyWith({
    PluginManagerLoadStatus? status,
    List<PluginDiscoveryEntry>? entries,
    String? selectedPluginId,
    bool clearSelection = false,
    String? errorMessage,
  }) {
    return PluginManagerState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      selectedPluginId:
          clearSelection ? null : selectedPluginId ?? this.selectedPluginId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
