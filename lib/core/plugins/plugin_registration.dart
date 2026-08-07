import 'plugin_manifest.dart';

enum PluginRegistrationStatus {
  ready,
  disabled,
  incompatible,
  invalid,
}

class PluginRegistration {
  const PluginRegistration({
    required this.manifestPath,
    required this.status,
    this.manifest,
    this.message = '',
  });

  final String manifestPath;
  final PluginManifest? manifest;
  final PluginRegistrationStatus status;
  final String message;

  bool get isReady => status == PluginRegistrationStatus.ready;
}
