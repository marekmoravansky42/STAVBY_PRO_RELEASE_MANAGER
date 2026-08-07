import 'plugin_permission.dart';
import 'plugin_permission_result.dart';
import 'plugin_security_audit.dart';
import 'plugin_security_exception.dart';
import 'plugin_security_policy.dart';

/// Central permission gate for compiled plugins.
class PluginPermissionManager {
  PluginPermissionManager({PluginSecurityAudit? audit})
      : audit = audit ?? PluginSecurityAudit();

  final PluginSecurityAudit audit;
  final Map<String, PluginSecurityPolicy> _policies =
      <String, PluginSecurityPolicy>{};

  void registerPolicy(String pluginId, PluginSecurityPolicy policy) {
    _policies[pluginId] = policy;
  }

  bool removePolicy(String pluginId) => _policies.remove(pluginId) != null;

  PluginSecurityPolicy? policyFor(String pluginId) => _policies[pluginId];

  bool hasPermission(String pluginId, PluginPermission permission) =>
      _policies[pluginId]?.allows(permission) ?? false;

  PluginPermissionResult checkPermission(
    String pluginId,
    PluginPermission permission,
  ) {
    final policy = _policies[pluginId];
    final allowed = policy?.allows(permission) ?? false;
    final reason = policy == null
        ? 'Plugin nemá zaregistrovanú bezpečnostnú politiku.'
        : allowed
            ? 'Oprávnenie bolo povolené bezpečnostnou politikou.'
            : 'Oprávnenie bolo zamietnuté bezpečnostnou politikou.';

    audit.record(
      PluginSecurityAuditEntry(
        pluginId: pluginId,
        permission: permission,
        allowed: allowed,
        reason: reason,
      ),
    );

    return PluginPermissionResult(
      pluginId: pluginId,
      permission: permission,
      allowed: allowed,
      reason: reason,
    );
  }

  void requirePermission(String pluginId, PluginPermission permission) {
    final result = checkPermission(pluginId, permission);
    if (!result.allowed) {
      throw PluginSecurityException(
        pluginId: pluginId,
        permission: permission,
        message: result.reason,
      );
    }
  }
}
