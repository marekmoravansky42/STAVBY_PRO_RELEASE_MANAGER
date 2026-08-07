import 'plugin_start_result.dart';
import 'plugin_state.dart';
import 'plugin_stop_result.dart';

class PluginReloadResult {
  const PluginReloadResult({
    required this.pluginId,
    required this.previousState,
    required this.state,
    required this.success,
    this.stopResult,
    this.startResult,
  });

  final String pluginId;
  final PluginState previousState;
  final PluginState state;
  final bool success;
  final PluginStopResult? stopResult;
  final PluginStartResult? startResult;
}
