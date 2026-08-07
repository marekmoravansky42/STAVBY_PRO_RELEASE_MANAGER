import 'plugin_permission.dart';

class PluginPermissionResult {
  const PluginPermissionResult({
    required this.pluginId,
    required this.permission,
    required this.allowed,
    required this.reason,
  });

  final String pluginId;
  final PluginPermission permission;
  final bool allowed;
  final String reason;
}
