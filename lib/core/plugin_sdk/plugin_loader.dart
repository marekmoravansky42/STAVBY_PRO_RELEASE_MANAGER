import 'plugin_api.dart';
import 'plugin_context.dart';
import 'plugin_registry.dart';

enum PluginLoadStatus { loaded, disabled, incompatible, invalid, failed }

class PluginLoadResult {
  const PluginLoadResult({required this.pluginId, required this.status, this.message = ''});

  final String pluginId;
  final PluginLoadStatus status;
  final String message;

  bool get isLoaded => status == PluginLoadStatus.loaded;
}

class PluginLoader {
  const PluginLoader({required this.hostVersion});

  final String hostVersion;

  Future<List<PluginLoadResult>> initializeRegistered({
    required PluginRegistry registry,
    required PluginContext context,
  }) async {
    final results = <PluginLoadResult>[];
    for (final plugin in registry.plugins) {
      results.add(await initialize(plugin, context));
    }
    return List<PluginLoadResult>.unmodifiable(results);
  }

  Future<PluginLoadResult> initialize(PluginApi plugin, PluginContext context) async {
    final descriptor = plugin.descriptor;
    final errors = descriptor.validate();
    if (errors.isNotEmpty) {
      return PluginLoadResult(
        pluginId: descriptor.id,
        status: PluginLoadStatus.invalid,
        message: errors.join(' '),
      );
    }
    if (!descriptor.enabledByDefault) {
      return PluginLoadResult(
        pluginId: descriptor.id,
        status: PluginLoadStatus.disabled,
        message: 'Plugin je predvolene vypnutý.',
      );
    }
    if (!descriptor.supportsHostVersion(hostVersion)) {
      return PluginLoadResult(
        pluginId: descriptor.id,
        status: PluginLoadStatus.incompatible,
        message: 'Vyžaduje Release Manager ${descriptor.minimumHostVersion} alebo novší.',
      );
    }
    try {
      await plugin.initialize(context);
      return PluginLoadResult(pluginId: descriptor.id, status: PluginLoadStatus.loaded);
    } catch (error) {
      return PluginLoadResult(
        pluginId: descriptor.id,
        status: PluginLoadStatus.failed,
        message: error.toString(),
      );
    }
  }

  Future<void> disposeAll(PluginRegistry registry) async {
    for (final plugin in registry.plugins.toList().reversed) {
      await plugin.dispose();
    }
  }
}
