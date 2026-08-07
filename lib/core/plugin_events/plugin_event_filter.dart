import 'plugin_event.dart';
import 'plugin_event_type.dart';

/// Restricts which events are delivered to a subscription.
class PluginEventFilter {
  const PluginEventFilter({this.pluginId, this.types});

  final String? pluginId;
  final Set<PluginEventType>? types;

  bool matches(PluginEvent event) {
    if (pluginId != null && event.pluginId != pluginId) return false;
    final acceptedTypes = types;
    return acceptedTypes == null || acceptedTypes.contains(event.type);
  }
}
