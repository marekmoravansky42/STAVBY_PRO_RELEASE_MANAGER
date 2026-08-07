import 'plugin_permission.dart';
import 'plugin_permission_manager.dart';

/// Permission-aware API surface passed to a plugin operation.
class PluginSecurityContext {
  const PluginSecurityContext({
    required this.pluginId,
    required this.permissionManager,
  });

  final String pluginId;
  final PluginPermissionManager permissionManager;

  bool can(PluginPermission permission) =>
      permissionManager.hasPermission(pluginId, permission);

  void require(PluginPermission permission) =>
      permissionManager.requirePermission(pluginId, permission);
}
