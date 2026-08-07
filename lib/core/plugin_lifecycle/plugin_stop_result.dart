import 'plugin_state.dart';

class PluginStopResult {
  const PluginStopResult._({
    required this.pluginId,
    required this.previousState,
    required this.state,
    required this.success,
    this.error,
    this.stackTrace,
  });

  factory PluginStopResult.stopped({
    required String pluginId,
    required PluginState previousState,
  }) =>
      PluginStopResult._(
        pluginId: pluginId,
        previousState: previousState,
        state: PluginState.stopped,
        success: true,
      );

  factory PluginStopResult.failed({
    required String pluginId,
    required PluginState previousState,
    required Object error,
    StackTrace? stackTrace,
  }) =>
      PluginStopResult._(
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
