import 'plugin_context.dart';
import 'plugin_descriptor.dart';

/// Compile-time API for Release Manager extensions.
///
/// Dart code is not loaded dynamically from arbitrary files. Plugins are
/// compiled with the application and registered explicitly through
/// [PluginRegistry].
abstract interface class PluginApi {
  PluginDescriptor get descriptor;

  Future<void> initialize(PluginContext context);

  Future<void> dispose();
}
