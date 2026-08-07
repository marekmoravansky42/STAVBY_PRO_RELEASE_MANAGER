import 'dart:io';

import 'package:crypto/crypto.dart';

import 'plugin_marketplace_index.dart';
import 'plugin_marketplace_manifest.dart';

class PluginMarketplaceValidationResult {
  const PluginMarketplaceValidationResult(this.errors);

  final List<String> errors;
  bool get isValid => errors.isEmpty;
}

/// Validates marketplace metadata and downloaded package checksums.
class PluginMarketplaceValidator {
  const PluginMarketplaceValidator();

  static final RegExp _identifier = RegExp(r'^[a-z0-9][a-z0-9._-]*$');
  static final RegExp _sha256 = RegExp(r'^[a-fA-F0-9]{64}$');

  PluginMarketplaceValidationResult validateManifest(
    PluginMarketplaceManifest manifest,
  ) {
    final errors = <String>[];
    if (!_identifier.hasMatch(manifest.id)) {
      errors.add('Neplatné ID pluginu: ${manifest.id}');
    }
    if (manifest.name.trim().isEmpty) errors.add('Názov pluginu je povinný.');
    if (manifest.author.trim().isEmpty) errors.add('Autor pluginu je povinný.');
    if (manifest.version.trim().isEmpty) errors.add('Verzia pluginu je povinná.');
    if (manifest.apiVersion.trim().isEmpty) errors.add('API verzia je povinná.');
    if (manifest.minimumReleaseManagerVersion.trim().isEmpty) {
      errors.add('Minimálna verzia Release Managera je povinná.');
    }
    final uri = Uri.tryParse(manifest.downloadUrl);
    if (uri == null || !uri.hasScheme || !<String>{'https', 'file'}.contains(uri.scheme)) {
      errors.add('Download URL musí používať schému https alebo file.');
    }
    if (!_sha256.hasMatch(manifest.sha256)) {
      errors.add('SHA-256 musí obsahovať presne 64 hexadecimálnych znakov.');
    }
    return PluginMarketplaceValidationResult(List<String>.unmodifiable(errors));
  }

  PluginMarketplaceValidationResult validateIndex(
    PluginMarketplaceIndex index,
  ) {
    final errors = <String>[];
    final ids = <String>{};
    if (index.schemaVersion < 1) errors.add('Neplatná verzia schémy indexu.');
    for (final plugin in index.plugins) {
      errors.addAll(validateManifest(plugin).errors);
      if (!ids.add(plugin.id)) errors.add('Duplicitné ID pluginu: ${plugin.id}');
    }
    return PluginMarketplaceValidationResult(List<String>.unmodifiable(errors));
  }

  Future<bool> verifyPackage(File package, String expectedSha256) async {
    if (!_sha256.hasMatch(expectedSha256) || !await package.exists()) return false;
    final digest = await sha256.bind(package.openRead()).first;
    return digest.toString().toLowerCase() == expectedSha256.toLowerCase();
  }
}
