import 'plugin_permission.dart';

class PluginSecurityAuditEntry {
  PluginSecurityAuditEntry({
    required this.pluginId,
    required this.permission,
    required this.allowed,
    required this.reason,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toUtc();

  final String pluginId;
  final PluginPermission permission;
  final bool allowed;
  final String reason;
  final DateTime timestamp;
}

class PluginSecurityAudit {
  final List<PluginSecurityAuditEntry> _entries = <PluginSecurityAuditEntry>[];

  List<PluginSecurityAuditEntry> get entries =>
      List<PluginSecurityAuditEntry>.unmodifiable(_entries);

  void record(PluginSecurityAuditEntry entry) => _entries.add(entry);

  void clear() => _entries.clear();
}
