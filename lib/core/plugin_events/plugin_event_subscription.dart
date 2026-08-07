import 'dart:async';

import 'plugin_event.dart';
import 'plugin_event_filter.dart';

typedef PluginEventHandler = FutureOr<void> Function(PluginEvent event);

/// Handle returned by [PluginEventBus.subscribe].
class PluginEventSubscription {
  PluginEventSubscription({
    required this.id,
    required this.handler,
    required this.filter,
    required void Function(String id) onCancel,
  }) : _onCancel = onCancel;

  final String id;
  final PluginEventHandler handler;
  final PluginEventFilter filter;
  final void Function(String id) _onCancel;
  bool _isActive = true;

  bool get isActive => _isActive;

  void cancel() {
    if (!_isActive) return;
    _isActive = false;
    _onCancel(id);
  }
}
