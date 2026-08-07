import 'plugin_installation_check.dart';
import 'plugin_installation_result.dart';

class PluginInstallationLog {
  const PluginInstallationLog._();

  static String format(PluginInstallationValidationResult result) {
    final buffer = StringBuffer()
      ..writeln('Kontrola inštalácie pluginu: ${result.pluginId}')
      ..writeln('Stav: ${result.isReady ? 'READY FOR INSTALL' : 'BLOCKED'}');

    for (final check in result.checks) {
      final prefix = switch (check.status) {
        PluginInstallationCheckStatus.passed => '✓',
        PluginInstallationCheckStatus.warning => '!',
        PluginInstallationCheckStatus.failed => '✗',
      };
      buffer.writeln('$prefix ${check.title}: ${check.message}');
    }
    return buffer.toString().trimRight();
  }
}
