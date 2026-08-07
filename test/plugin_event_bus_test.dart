import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/core/plugin_events/plugin_events.dart';

void main() {
  test('delivers events to subscribers in registration order', () async {
    final bus = PluginEventBus();
    final calls = <String>[];

    bus.subscribe((event) => calls.add('first:${event.pluginId}'));
    bus.subscribe((event) => calls.add('second:${event.pluginId}'));

    final result = await bus.publish(
      PluginEvent(pluginId: 'test.plugin', type: PluginEventType.started),
    );

    expect(calls, <String>['first:test.plugin', 'second:test.plugin']);
    expect(result.matchedSubscriptions, 2);
    expect(result.deliveredSubscriptions, 2);
    expect(result.success, isTrue);
  });

  test('filters by plugin id and event type', () async {
    final bus = PluginEventBus();
    var calls = 0;

    bus.subscribe(
      (_) => calls++,
      filter: const PluginEventFilter(
        pluginId: 'accepted.plugin',
        types: <PluginEventType>{PluginEventType.failed},
      ),
    );

    await bus.publish(
      PluginEvent(pluginId: 'accepted.plugin', type: PluginEventType.started),
    );
    await bus.publish(
      PluginEvent(pluginId: 'other.plugin', type: PluginEventType.failed),
    );
    await bus.publish(
      PluginEvent(pluginId: 'accepted.plugin', type: PluginEventType.failed),
    );

    expect(calls, 1);
  });

  test('isolates a failing subscriber', () async {
    final bus = PluginEventBus();
    var healthyCalls = 0;

    bus.subscribe((_) => throw StateError('subscriber failed'));
    bus.subscribe((_) => healthyCalls++);

    final result = await bus.publish(
      PluginEvent(pluginId: 'test.plugin', type: PluginEventType.loaded),
    );

    expect(healthyCalls, 1);
    expect(result.deliveredSubscriptions, 1);
    expect(result.failures, hasLength(1));
    expect(result.success, isFalse);
  });

  test('cancelled subscription no longer receives events', () async {
    final bus = PluginEventBus();
    var calls = 0;
    final subscription = bus.subscribe((_) => calls++);

    subscription.cancel();
    await bus.publish(
      PluginEvent(pluginId: 'test.plugin', type: PluginEventType.stopped),
    );

    expect(calls, 0);
    expect(bus.subscriptionCount, 0);
  });
}
