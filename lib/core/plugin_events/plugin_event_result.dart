/// Delivery failure for one subscriber.
class PluginEventDeliveryFailure {
  const PluginEventDeliveryFailure({
    required this.subscriptionId,
    required this.error,
    required this.stackTrace,
  });

  final String subscriptionId;
  final Object error;
  final StackTrace stackTrace;
}

/// Summary returned after an event has been dispatched.
class PluginEventResult {
  const PluginEventResult({
    required this.eventId,
    required this.matchedSubscriptions,
    required this.deliveredSubscriptions,
    required this.failures,
  });

  final String eventId;
  final int matchedSubscriptions;
  final int deliveredSubscriptions;
  final List<PluginEventDeliveryFailure> failures;

  bool get success => failures.isEmpty;
}
