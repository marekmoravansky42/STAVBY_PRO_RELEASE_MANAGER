import 'plugin_event_type.dart';

/// Immutable message exchanged through [PluginEventBus].
class PluginEvent {
  PluginEvent({
    required this.pluginId,
    required this.type,
    this.source = 'plugin-platform',
    this.payload = const <String, Object?>{},
    DateTime? timestamp,
    String? id,
  })  : timestamp = timestamp ?? DateTime.now().toUtc(),
        id = id ?? _createId();

  final String id;
  final String pluginId;
  final PluginEventType type;
  final String source;
  final Map<String, Object?> payload;
  final DateTime timestamp;

  static int _sequence = 0;

  static String _createId() {
    _sequence++;
    return '${DateTime.now().microsecondsSinceEpoch}-$_sequence';
  }
}
