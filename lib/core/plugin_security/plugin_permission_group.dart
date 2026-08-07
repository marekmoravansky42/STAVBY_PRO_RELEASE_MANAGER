import 'plugin_permission.dart';

/// Logical groups used by diagnostics and future permission UI.
enum PluginPermissionGroup {
  project,
  configuration,
  sourceControl,
  release,
  system,
}

extension PluginPermissionGroupPermissions on PluginPermissionGroup {
  Set<PluginPermission> get permissions => switch (this) {
        PluginPermissionGroup.project => const <PluginPermission>{
            PluginPermission.readProject,
            PluginPermission.writeProject,
          },
        PluginPermissionGroup.configuration => const <PluginPermission>{
            PluginPermission.readConfiguration,
            PluginPermission.writeConfiguration,
          },
        PluginPermissionGroup.sourceControl => const <PluginPermission>{
            PluginPermission.gitRead,
            PluginPermission.gitWrite,
            PluginPermission.githubApi,
            PluginPermission.network,
          },
        PluginPermissionGroup.release => const <PluginPermission>{
            PluginPermission.exportRelease,
            PluginPermission.fileSystem,
          },
        PluginPermissionGroup.system => const <PluginPermission>{
            PluginPermission.diagnostics,
            PluginPermission.systemCommand,
          },
      };
}
