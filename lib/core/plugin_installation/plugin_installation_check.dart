enum PluginInstallationCheckStatus { passed, warning, failed }

class PluginInstallationCheck {
  const PluginInstallationCheck({
    required this.title,
    required this.message,
    required this.status,
  });

  final String title;
  final String message;
  final PluginInstallationCheckStatus status;

  bool get isBlocking => status == PluginInstallationCheckStatus.failed;
}
