import '../plugin_discovery/plugin_manifest.dart';

/// A validated plugin package ready for installation.
class PluginPackage {
  const PluginPackage({
    required this.sourceDirectory,
    required this.manifest,
  });

  final String sourceDirectory;
  final PluginManifest manifest;

  String get id => manifest.id;
  String get version => manifest.version;
}
