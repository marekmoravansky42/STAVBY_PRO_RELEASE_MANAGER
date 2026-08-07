import 'plugin_manifest.dart';
import 'plugin_scan_issue.dart';

class PluginScanResult {
  const PluginScanResult({
    this.manifests = const <PluginManifest>[],
    this.issues = const <PluginScanIssue>[],
  });

  final List<PluginManifest> manifests;
  final List<PluginScanIssue> issues;

  bool get hasIssues => issues.isNotEmpty;
}
