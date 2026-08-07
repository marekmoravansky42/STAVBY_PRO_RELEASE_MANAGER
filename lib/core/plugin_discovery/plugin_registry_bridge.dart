import '../plugin_sdk/plugin_api.dart';
import '../plugin_sdk/plugin_registry.dart';
import 'plugin_manifest.dart';

/// Bridges file-based manifests with plugins already compiled into the app.
///
/// No Dart code is loaded dynamically. A manifest may only expose a plugin
/// that is already present in [PluginRegistry].
class PluginRegistryBridge {
  const PluginRegistryBridge(this.registry);

  final PluginRegistry registry;

  PluginApi? resolve(PluginManifest manifest) => registry.find(manifest.id);

  List<String> validateMatch(PluginManifest manifest, PluginApi plugin) {
    final descriptor = plugin.descriptor;
    final errors = <String>[];

    if (descriptor.id != manifest.id) {
      errors.add('ID manifestu sa nezhoduje s descriptorom pluginu.');
    }
    if (descriptor.name != manifest.name) {
      errors.add('Názov manifestu sa nezhoduje s descriptorom pluginu.');
    }
    if (descriptor.version != manifest.version) {
      errors.add('Verzia manifestu sa nezhoduje s descriptorom pluginu.');
    }

    return List<String>.unmodifiable(errors);
  }
}
