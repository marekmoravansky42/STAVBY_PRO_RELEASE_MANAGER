import 'plugin_installation_check.dart';

class PluginInstallationValidationResult {
  const PluginInstallationValidationResult({
    required this.pluginId,
    required this.checks,
  });

  final String pluginId;
  final List<PluginInstallationCheck> checks;

  bool get isReady => !checks.any((check) => check.isBlocking);
  int get passedCount => checks
      .where((check) => check.status == PluginInstallationCheckStatus.passed)
      .length;
  int get warningCount => checks
      .where((check) => check.status == PluginInstallationCheckStatus.warning)
      .length;
  int get failedCount => checks
      .where((check) => check.status == PluginInstallationCheckStatus.failed)
      .length;
}
