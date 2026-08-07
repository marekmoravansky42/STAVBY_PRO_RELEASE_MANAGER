import 'plugin_api.dart';
import 'plugin_capabilities.dart';

class PluginRegistry {
  final Map<String, PluginApi> _plugins = <String, PluginApi>{};

  Iterable<PluginApi> get plugins => List<PluginApi>.unmodifiable(_plugins.values);

  void register(PluginApi plugin) {
    final id = plugin.descriptor.id;
    final errors = plugin.descriptor.validate();
    if (errors.isNotEmpty) {
      throw FormatException('Neplatný plugin $id: ${errors.join(' ')}');
    }
    if (_plugins.containsKey(id)) {
      throw StateError('Plugin s ID "$id" je už registrovaný.');
    }
    _plugins[id] = plugin;
  }

  PluginApi? find(String id) => _plugins[id];

  Iterable<PluginApi> withCapability(PluginCapability capability) =>
      plugins.where((plugin) => plugin.descriptor.capabilities.contains(capability));

  bool unregister(String id) => _plugins.remove(id) != null;

  void clear() => _plugins.clear();
}
