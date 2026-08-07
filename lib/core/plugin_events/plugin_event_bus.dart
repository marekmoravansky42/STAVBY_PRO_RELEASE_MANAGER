import 'dart:async';

import 'plugin_event.dart';
import 'plugin_event_filter.dart';
import 'plugin_event_result.dart';
import 'plugin_event_subscription.dart';

/// In-process event bus for communication between compile-time plugins.
///
/// Subscribers are invoked in registration order. A failing subscriber is
/// recorded in the result and does not prevent delivery to other subscribers.
class PluginEventBus {
  final Map<String, PluginEventSubscription> _subscriptions =
      <String, PluginEventSubscription>{};
  int _sequence = 0;

  int get subscriptionCount => _subscriptions.length;

  PluginEventSubscription subscribe(
    PluginEventHandler handler, {
    PluginEventFilter filter = const PluginEventFilter(),
  }) {
    final id = 'subscription-${++_sequence}';
    final subscription = PluginEventSubscription(
      id: id,
      handler: handler,
      filter: filter,
      onCancel: _subscriptions.remove,
    );
    _subscriptions[id] = subscription;
    return subscription;
  }

  bool unsubscribe(String subscriptionId) {
    final subscription = _subscriptions.remove(subscriptionId);
    if (subscription == null) return false;
    subscription.cancel();
    return true;
  }

  void clearSubscriptions() {
    final current = _subscriptions.values.toList(growable: false);
    _subscriptions.clear();
    for (final subscription in current) {
      subscription.cancel();
    }
  }

  Future<PluginEventResult> publish(PluginEvent event) async {
    final matching = _subscriptions.values
        .where((subscription) =>
            subscription.isActive && subscription.filter.matches(event))
        .toList(growable: false);
    final failures = <PluginEventDeliveryFailure>[];
    var delivered = 0;

    for (final subscription in matching) {
      if (!subscription.isActive) continue;
      try {
        await Future<void>.sync(() => subscription.handler(event));
        delivered++;
      } catch (error, stackTrace) {
        failures.add(
          PluginEventDeliveryFailure(
            subscriptionId: subscription.id,
            error: error,
            stackTrace: stackTrace,
          ),
        );
      }
    }

    return PluginEventResult(
      eventId: event.id,
      matchedSubscriptions: matching.length,
      deliveredSubscriptions: delivered,
      failures: List<PluginEventDeliveryFailure>.unmodifiable(failures),
    );
  }
}
