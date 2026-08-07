import 'plugin_manifest.dart';
import 'plugin_scan_issue.dart';

enum PluginDiscoveryStatus {
  available,
  disabled,
  missingCompiledPlugin,
  descriptorMismatch,
}

class PluginDiscoveryEntry {
  const PluginDiscoveryEntry({
    required this.manifest,
    required this.status,
    this.message = '',
  });

  final PluginManifest manifest;
  final PluginDiscoveryStatus status;
  final String message;

  bool get isAvailable => status == PluginDiscoveryStatus.available;
}

class PluginDiscoveryReport {
  const PluginDiscoveryReport({
    this.entries = const <PluginDiscoveryEntry>[],
    this.scanIssues = const <PluginScanIssue>[],
  });

  final List<PluginDiscoveryEntry> entries;
  final List<PluginScanIssue> scanIssues;

  Iterable<PluginDiscoveryEntry> get available =>
      entries.where((entry) => entry.isAvailable);

  bool get hasProblems =>
      scanIssues.isNotEmpty || entries.any((entry) => !entry.isAvailable);
}
