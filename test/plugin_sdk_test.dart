import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/core/plugin_sdk/plugin_sdk.dart';

void main() {
  test('descriptor validates and checks host compatibility', () {
    const descriptor = PluginDescriptor(
      id: 'stavby.exporter',
      name: 'Exporter',
      version: '1.0.0',
      minimumHostVersion: '6.3.0',
      capabilities: <PluginCapability>{PluginCapability.artifactExporter},
    );

    expect(descriptor.validate(), isEmpty);
    expect(descriptor.supportsHostVersion('6.3.4'), isTrue);
    expect(descriptor.supportsHostVersion('6.2.9'), isFalse);
  });

  test('registry rejects duplicate plugin IDs', () {
    final registry = PluginRegistry();
    registry.register(_TestPlugin());
    expect(() => registry.register(_TestPlugin()), throwsStateError);
  });

  test('loader initializes compatible compiled plugin', () async {
    final plugin = _TestPlugin();
    final loader = PluginLoader(hostVersion: '6.3.4');
    final result = await loader.initialize(plugin, PluginContext());

    expect(result.status, PluginLoadStatus.loaded);
    expect(plugin.initialized, isTrue);
  });
}

class _TestPlugin implements PluginApi {
  bool initialized = false;

  @override
  PluginDescriptor get descriptor => const PluginDescriptor(
        id: 'test.plugin',
        name: 'Test plugin',
        version: '1.0.0',
        minimumHostVersion: '6.3.0',
        capabilities: <PluginCapability>{PluginCapability.pipelineStep},
      );

  @override
  Future<void> initialize(PluginContext context) async {
    initialized = true;
  }

  @override
  Future<void> dispose() async {}
}
