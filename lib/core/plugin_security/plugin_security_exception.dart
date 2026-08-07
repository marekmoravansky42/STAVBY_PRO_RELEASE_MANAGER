import 'plugin_permission.dart';

class PluginSecurityException implements Exception {
  const PluginSecurityException({
    required this.pluginId,
    required this.permission,
    required this.message,
  });

  final String pluginId;
  final PluginPermission permission;
  final String message;

  @override
  String toString() =>
      'PluginSecurityException($pluginId, ${permission.wireName}): $message';
}
