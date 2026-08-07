import 'dart:convert';
import 'dart:io';

import '../plugins/plugin_manifest.dart';
import '../plugins/plugin_registration.dart';

/// Discovers and validates manifest-based project extensions.
class PluginService {
  const PluginService({required this.releaseManagerVersion});

  final String releaseManagerVersion;

  Future<List<PluginRegistration>> discover(String pluginsDirectoryPath) async {
    final directory = Directory(pluginsDirectoryPath);
    if (!await directory.exists()) {
      return const <PluginRegistration>[];
    }

    final registrations = <PluginRegistration>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! Directory) {
        continue;
      }
      final manifestFile = File(
        '${entity.path}${Platform.pathSeparator}plugin.json',
      );
      if (!await manifestFile.exists()) {
        continue;
      }
      registrations.add(await _readRegistration(manifestFile));
    }

    registrations.sort((a, b) {
      final left = a.manifest?.name.toLowerCase() ?? a.manifestPath;
      final right = b.manifest?.name.toLowerCase() ?? b.manifestPath;
      return left.compareTo(right);
    });
    return List<PluginRegistration>.unmodifiable(registrations);
  }

  Future<PluginRegistration> _readRegistration(File file) async {
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Plugin manifest musí byť JSON objekt.');
      }
      final manifest = PluginManifest.fromJson(decoded);
      validate(manifest);

      if (!manifest.enabled) {
        return PluginRegistration(
          manifestPath: file.path,
          manifest: manifest,
          status: PluginRegistrationStatus.disabled,
          message: 'Plugin je vypnutý v manifeste.',
        );
      }

      if (!_isCompatible(
        current: releaseManagerVersion,
        minimum: manifest.minimumReleaseManagerVersion,
      )) {
        return PluginRegistration(
          manifestPath: file.path,
          manifest: manifest,
          status: PluginRegistrationStatus.incompatible,
          message: 'Plugin vyžaduje Release Manager '
              '${manifest.minimumReleaseManagerVersion} alebo novší.',
        );
      }

      return PluginRegistration(
        manifestPath: file.path,
        manifest: manifest,
        status: PluginRegistrationStatus.ready,
        message: 'Plugin je pripravený na registráciu.',
      );
    } on Object catch (error) {
      return PluginRegistration(
        manifestPath: file.path,
        status: PluginRegistrationStatus.invalid,
        message: error.toString(),
      );
    }
  }

  void validate(PluginManifest manifest) {
    if (manifest.id.isEmpty) {
      throw const FormatException('Plugin nemá ID.');
    }
    if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(manifest.id)) {
      throw const FormatException('ID pluginu obsahuje nepovolené znaky.');
    }
    if (manifest.name.isEmpty) {
      throw const FormatException('Plugin nemá názov.');
    }
    if (manifest.version.isEmpty) {
      throw const FormatException('Plugin nemá verziu.');
    }
    if (manifest.minimumReleaseManagerVersion.isEmpty) {
      throw const FormatException('Plugin nemá minimálnu verziu správcu.');
    }
    const supportedPlatforms = <String>{'windows', 'android'};
    if (manifest.platforms.isEmpty ||
        manifest.platforms.any(
          (platform) => !supportedPlatforms.contains(platform),
        )) {
      throw const FormatException(
        'Plugin obsahuje prázdnu alebo nepodporovanú platformu.',
      );
    }
  }

  bool _isCompatible({required String current, required String minimum}) {
    final currentParts = _versionParts(current);
    final minimumParts = _versionParts(minimum);
    for (var index = 0; index < 3; index++) {
      if (currentParts[index] > minimumParts[index]) {
        return true;
      }
      if (currentParts[index] < minimumParts[index]) {
        return false;
      }
    }
    return true;
  }

  List<int> _versionParts(String source) {
    final normalized = source.trim().replaceFirst(RegExp(r'^[^0-9]*'), '');
    final core = normalized.split('+').first.split('-').first;
    final raw = core.split('.');
    return List<int>.generate(
      3,
      (index) => index < raw.length ? int.tryParse(raw[index]) ?? 0 : 0,
      growable: false,
    );
  }
}
