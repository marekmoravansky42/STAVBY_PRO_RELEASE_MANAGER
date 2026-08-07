import 'dart:io';

import '../plugin_discovery/plugin_manifest.dart';

class InstalledPluginRecord {
  const InstalledPluginRecord({
    required this.manifest,
    required this.directory,
    required this.manifestFile,
    required this.modifiedAt,
  });

  final PluginManifest manifest;
  final Directory directory;
  final File manifestFile;
  final DateTime modifiedAt;

  bool get enabled => manifest.enabled;
}
