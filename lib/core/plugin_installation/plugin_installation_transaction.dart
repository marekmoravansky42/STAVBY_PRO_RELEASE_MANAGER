import 'dart:io';

class PluginInstallationTransaction {
  PluginInstallationTransaction({
    required this.pluginId,
    required this.sourceDirectory,
    required this.startedAt,
  });

  final String pluginId;
  final Directory sourceDirectory;
  final DateTime startedAt;
  final List<String> _log = <String>[];

  List<String> get log => List<String>.unmodifiable(_log);

  void add(String message) {
    final time = DateTime.now().toIso8601String();
    _log.add('$time  $message');
  }

  String formatLog() => _log.join('\n');
}
