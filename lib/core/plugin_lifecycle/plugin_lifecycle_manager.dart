import '../plugin_sdk/plugin_api.dart';
import '../plugin_sdk/plugin_context.dart';
import '../plugin_sdk/plugin_registry.dart';
import 'plugin_reload_result.dart';
import 'plugin_start_result.dart';
import 'plugin_state.dart';
import 'plugin_stop_result.dart';

/// Coordinates the lifecycle of compile-time plugins.
///
/// One plugin failure is captured as a result and does not stop lifecycle
/// operations for other plugins.
class PluginLifecycleManager {
  PluginLifecycleManager({required PluginRegistry registry}) : _registry = registry {
    synchronizeRegistry();
  }

  final PluginRegistry _registry;
  final Map<String, PluginState> _states = <String, PluginState>{};

  Map<String, PluginState> get states => Map<String, PluginState>.unmodifiable(_states);

  PluginState? stateOf(String pluginId) => _states[pluginId];

  /// Adds newly registered plugins to lifecycle tracking and removes entries
  /// that are no longer present in the registry.
  void synchronizeRegistry() {
    final registeredIds = _registry.plugins.map((plugin) => plugin.descriptor.id).toSet();
    _states.removeWhere((id, _) => !registeredIds.contains(id));
    for (final id in registeredIds) {
      _states.putIfAbsent(id, () => PluginState.registered);
    }
  }

  void markLoaded(String pluginId) {
    _requirePlugin(pluginId);
    _states[pluginId] = PluginState.loaded;
  }

  Future<PluginStartResult> startPlugin(
    String pluginId,
    PluginContext context,
  ) async {
    final plugin = _requirePlugin(pluginId);
    final previousState = _states[pluginId] ?? PluginState.registered;

    try {
      await plugin.initialize(context);
      _states[pluginId] = PluginState.started;
      return PluginStartResult.started(
        pluginId: pluginId,
        previousState: previousState,
      );
    } catch (error, stackTrace) {
      _states[pluginId] = PluginState.failed;
      return PluginStartResult.failed(
        pluginId: pluginId,
        previousState: previousState,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<PluginStopResult> stopPlugin(String pluginId) async {
    final plugin = _requirePlugin(pluginId);
    final previousState = _states[pluginId] ?? PluginState.registered;

    try {
      await plugin.dispose();
      _states[pluginId] = PluginState.stopped;
      return PluginStopResult.stopped(
        pluginId: pluginId,
        previousState: previousState,
      );
    } catch (error, stackTrace) {
      _states[pluginId] = PluginState.failed;
      return PluginStopResult.failed(
        pluginId: pluginId,
        previousState: previousState,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<PluginReloadResult> reloadPlugin(
    String pluginId,
    PluginContext context,
  ) async {
    final previousState = stateOf(pluginId) ?? PluginState.registered;
    final stopResult = await stopPlugin(pluginId);
    if (!stopResult.success) {
      return PluginReloadResult(
        pluginId: pluginId,
        previousState: previousState,
        state: PluginState.failed,
        success: false,
        stopResult: stopResult,
      );
    }

    final startResult = await startPlugin(pluginId, context);
    return PluginReloadResult(
      pluginId: pluginId,
      previousState: previousState,
      state: startResult.state,
      success: startResult.success,
      stopResult: stopResult,
      startResult: startResult,
    );
  }

  Future<List<PluginStartResult>> startAll(PluginContext context) async {
    synchronizeRegistry();
    final results = <PluginStartResult>[];
    for (final plugin in _registry.plugins) {
      results.add(await startPlugin(plugin.descriptor.id, context));
    }
    return List<PluginStartResult>.unmodifiable(results);
  }

  Future<List<PluginStopResult>> stopAll() async {
    synchronizeRegistry();
    final results = <PluginStopResult>[];
    for (final plugin in _registry.plugins) {
      results.add(await stopPlugin(plugin.descriptor.id));
    }
    return List<PluginStopResult>.unmodifiable(results);
  }

  PluginApi _requirePlugin(String pluginId) {
    synchronizeRegistry();
    final plugin = _registry.find(pluginId);
    if (plugin == null) {
      throw StateError('Plugin s ID "$pluginId" nie je registrovaný.');
    }
    return plugin;
  }
}
