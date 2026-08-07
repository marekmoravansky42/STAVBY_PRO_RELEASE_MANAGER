import 'plugin_state.dart';

class PluginStartResult {
  const PluginStartResult._({
    required this.pluginId,
    required this.previousState,
    required this.state,
    required this.success,
    this.error,
    this.stackTrace,
  });

  factory PluginStartResult.started({
    required String pluginId,
    required PluginState previousState,
  }) =>
      PluginStartResult._(
        pluginId: pluginId,
        previousState: previousState,
        state: PluginState.started,
        success: true,
      );

  factory PluginStartResult.failed({
    required String pluginId,
    required PluginState previousState,
    required Object error,
    StackTrace? stackTrace,
  }) =>
      PluginStartResult._(
        pluginId: pluginId,
        previousState: previousState,
        state: PluginState.failed,
        success: false,
        error: error,
        stackTrace: stackTrace,
      );

  final String pluginId;
  final PluginState previousState;
  final PluginState state;
  final bool success;
  final Object? error;
  final StackTrace? stackTrace;
}
