import 'dart:io';

import 'package:path/path.dart' as p;

import '../plugin_discovery/plugin_manifest_parser.dart';
import '../plugin_security/plugin_permission_validator.dart';
import 'plugin_package.dart';

class PluginPackageValidationResult {
  const PluginPackageValidationResult({
    required this.package,
    required this.errors,
  });

  final PluginPackage? package;
  final List<String> errors;

  bool get isValid => package != null && errors.isEmpty;
}

/// Validates an extracted package directory before any filesystem mutation.
class PluginPackageValidator {
  const PluginPackageValidator({
    this.supportedApiVersion = '1.0.0',
    this.manifestParser = const PluginManifestParser(),
    this.permissionValidator = const PluginPermissionValidator(),
  });

  final String supportedApiVersion;
  final PluginManifestParser manifestParser;
  final PluginPermissionValidator permissionValidator;

  Future<PluginPackageValidationResult> validateDirectory(
    Directory directory,
  ) async {
    final errors = <String>[];
    if (!await directory.exists()) {
      return PluginPackageValidationResult(
        package: null,
        errors: const <String>['Adresár pluginového balíka neexistuje.'],
      );
    }

    final manifestFile = File(p.join(directory.path, 'plugin.json'));
    if (!await manifestFile.exists()) {
      return PluginPackageValidationResult(
        package: null,
        errors: const <String>['Balík neobsahuje povinný súbor plugin.json.'],
      );
    }

    final parsed = manifestParser.parse(await manifestFile.readAsString());
    if (!parsed.isValid || parsed.value == null) {
      return PluginPackageValidationResult(
        package: null,
        errors: parsed.errors,
      );
    }

    final manifest = parsed.value!;
    if (!_isApiCompatible(manifest.apiVersion)) {
      errors.add(
        'Plugin vyžaduje API ${manifest.apiVersion}, podporované je $supportedApiVersion.',
      );
    }

    final permissions = permissionValidator.validate(manifest.permissions);
    errors.addAll(permissions.errors);

    if (manifest.entryPoint.isNotEmpty) {
      final entryPoint = File(p.join(directory.path, manifest.entryPoint));
      if (!await entryPoint.exists()) {
        errors.add('Deklarovaný entryPoint neexistuje: ${manifest.entryPoint}.');
      }
    }

    if (errors.isNotEmpty) {
      return PluginPackageValidationResult(
        package: null,
        errors: List<String>.unmodifiable(errors),
      );
    }

    return PluginPackageValidationResult(
      package: PluginPackage(
        sourceDirectory: directory.path,
        manifest: manifest,
      ),
      errors: const <String>[],
    );
  }

  bool _isApiCompatible(String requested) {
    final requestedMajor = int.tryParse(requested.split('.').first);
    final supportedMajor = int.tryParse(supportedApiVersion.split('.').first);
    return requestedMajor != null && requestedMajor == supportedMajor;
  }
}
