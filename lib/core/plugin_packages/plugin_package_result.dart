/// Result of an install, update, uninstall or rollback operation.
class PluginPackageResult {
  const PluginPackageResult._({
    required this.success,
    required this.message,
    this.pluginId,
    this.installedPath,
    this.backupPath,
    this.error,
    this.stackTrace,
  });

  final bool success;
  final String message;
  final String? pluginId;
  final String? installedPath;
  final String? backupPath;
  final Object? error;
  final StackTrace? stackTrace;

  factory PluginPackageResult.ok({
    required String message,
    String? pluginId,
    String? installedPath,
    String? backupPath,
  }) =>
      PluginPackageResult._(
        success: true,
        message: message,
        pluginId: pluginId,
        installedPath: installedPath,
        backupPath: backupPath,
      );

  factory PluginPackageResult.failed({
    required String message,
    String? pluginId,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      PluginPackageResult._(
        success: false,
        message: message,
        pluginId: pluginId,
        error: error,
        stackTrace: stackTrace,
      );
}
