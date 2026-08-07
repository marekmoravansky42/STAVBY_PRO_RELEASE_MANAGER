enum PluginScanIssueType {
  directoryMissing,
  readFailed,
  invalidManifest,
  duplicatePluginId,
}

class PluginScanIssue {
  const PluginScanIssue({
    required this.type,
    required this.message,
    this.path,
    this.pluginId,
  });

  final PluginScanIssueType type;
  final String message;
  final String? path;
  final String? pluginId;
}
