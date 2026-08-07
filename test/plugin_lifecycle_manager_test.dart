import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/core/plugin_lifecycle/plugin_lifecycle.dart';
import 'package:stavby_pro_release_manager/core/plugin_sdk/plugin_sdk.dart';

void main() {
  test('tracks registration, start, stop and reload states', () async {
    final registry = PluginRegistry()..register(_LifecyclePlugin('test.lifecycle'));
    final manager = PluginLifecycleManager(registry: registry);

    expect(manager.stateOf('test.lifecycle'), PluginState.registered);

    manager.markLoaded('test.lifecycle');
    expect(manager.stateOf('test.lifecycle'), PluginState.loaded);

    final start = await manager.startPlugin('test.lifecycle', PluginContext());
    expect(start.success, isTrue);
    expect(manager.stateOf('test.lifecycle'), PluginState.started);

    final stop = await manager.stopPlugin('test.lifecycle');
    expect(stop.success, isTrue);
    expect(manager.stateOf('test.lifecycle'), PluginState.stopped);

    final reload = await manager.reloadPlugin('test.lifecycle', PluginContext());
    expect(reload.success, isTrue);
    expect(manager.stateOf('test.lifecycle'), PluginState.started);
  });

  test('isolates a failing plugin from other plugins', () async {
    final healthy = _LifecyclePlugin('test.healthy');
    final failing = _LifecyclePlugin('test.failing', failOnStart: true);
    final registry = PluginRegistry()
      ..register(failing)
      ..register(healthy);
    final manager = PluginLifecycleManager(registry: registry);

    final results = await manager.startAll(PluginContext());

    expect(results, hasLength(2));
    expect(manager.stateOf('test.failing'), PluginState.failed);
    expect(manager.stateOf('test.healthy'), PluginState.started);
    expect(healthy.initializeCalls, 1);
  });

  test('removes lifecycle state after plugin is unregistered', () {
    final registry = PluginRegistry()..register(_LifecyclePlugin('test.removed'));
    final manager = PluginLifecycleManager(registry: registry);

    registry.unregister('test.removed');
    manager.synchronizeRegistry();

    expect(manager.stateOf('test.removed'), isNull);
  });
}

class _LifecyclePlugin implements PluginApi {
  _LifecyclePlugin(this.id, {this.failOnStart = false});

  final String id;
  final bool failOnStart;
  int initializeCalls = 0;

  @override
  PluginDescriptor get descriptor => PluginDescriptor(
        id: id,
        name: 'Lifecycle test plugin',
        version: '1.0.0',
        minimumHostVersion: '6.3.0',
        capabilities: const <PluginCapability>{PluginCapability.pipelineStep},
      );

  @override
  Future<void> initialize(PluginContext context) async {
    initializeCalls++;
    if (failOnStart) throw StateError('Start failed');
  }

  @override
  Future<void> dispose() async {}
}
