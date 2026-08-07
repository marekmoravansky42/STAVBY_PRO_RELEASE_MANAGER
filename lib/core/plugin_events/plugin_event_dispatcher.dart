import 'plugin_event.dart';
import 'plugin_event_bus.dart';
import 'plugin_event_result.dart';
import 'plugin_event_type.dart';

/// Convenience facade used by plugin-platform services.
class PluginEventDispatcher {
  const PluginEventDispatcher(this.bus);

  final PluginEventBus bus;

  Future<PluginEventResult> dispatch({
    required String pluginId,
    required PluginEventType type,
    String source = 'plugin-platform',
    Map<String, Object?> payload = const <String, Object?>{},
  }) {
    return bus.publish(
      PluginEvent(
        pluginId: pluginId,
        type: type,
        source: source,
        payload: payload,
      ),
    );
  }
}
