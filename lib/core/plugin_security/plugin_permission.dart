/// Sensitive operations that a plugin may request from Release Manager.
enum PluginPermission {
  readProject,
  writeProject,
  readConfiguration,
  writeConfiguration,
  gitRead,
  gitWrite,
  githubApi,
  exportRelease,
  fileSystem,
  network,
  diagnostics,
  systemCommand,
}

extension PluginPermissionWireName on PluginPermission {
  String get wireName => switch (this) {
        PluginPermission.readProject => 'readProject',
        PluginPermission.writeProject => 'writeProject',
        PluginPermission.readConfiguration => 'readConfiguration',
        PluginPermission.writeConfiguration => 'writeConfiguration',
        PluginPermission.gitRead => 'gitRead',
        PluginPermission.gitWrite => 'gitWrite',
        PluginPermission.githubApi => 'githubApi',
        PluginPermission.exportRelease => 'exportRelease',
        PluginPermission.fileSystem => 'fileSystem',
        PluginPermission.network => 'network',
        PluginPermission.diagnostics => 'diagnostics',
        PluginPermission.systemCommand => 'systemCommand',
      };

  static PluginPermission? tryParse(String value) {
    for (final permission in PluginPermission.values) {
      if (permission.wireName == value) return permission;
    }
    return null;
  }
}
