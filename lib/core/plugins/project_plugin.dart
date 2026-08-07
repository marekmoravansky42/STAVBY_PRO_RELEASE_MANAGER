import 'plugin_manifest.dart';

/// Compile-time contract for future project-specific extensions.
///
/// Implementations can later connect project-specific behavior to the shared
/// release engine without coupling that engine to one concrete project.
abstract interface class ProjectPlugin {
  PluginManifest get manifest;

  Future<void> initialize();

  Future<void> analyze();

  Future<void> build();

  Future<void> export();

  Future<void> generateReport();
}
