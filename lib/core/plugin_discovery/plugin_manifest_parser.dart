import 'dart:convert';

import 'plugin_manifest.dart';
import 'plugin_validation_result.dart';

/// Parses plugin.json content without throwing on malformed user input.
class PluginManifestParser {
  const PluginManifestParser();

  PluginValidationResult<PluginManifest> parse(String source) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      return PluginValidationResult<PluginManifest>.invalid(
        <String>['Manifest nie je platný JSON: ${error.message}'],
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return PluginValidationResult<PluginManifest>.invalid(
        const <String>['Koreň manifestu musí byť JSON objekt.'],
      );
    }

    final errors = _validate(decoded);
    if (errors.isNotEmpty) {
      return PluginValidationResult<PluginManifest>.invalid(errors);
    }

    return PluginValidationResult<PluginManifest>.valid(
      PluginManifest.fromJson(decoded),
    );
  }

  List<String> _validate(Map<String, dynamic> json) {
    final errors = <String>[];

    _requireNonEmptyString(json, 'id', errors);
    _requireNonEmptyString(json, 'name', errors);
    _requireSemanticVersion(json, 'version', errors);
    _requireSemanticVersion(json, 'apiVersion', errors);

    final id = json['id'];
    if (id is String &&
        id.trim().isNotEmpty &&
        !RegExp(r'^[a-z0-9][a-z0-9._-]*$').hasMatch(id.trim())) {
      errors.add(
        'Pole "id" môže obsahovať iba malé písmená, čísla, bodky, pomlčky a podčiarkovníky.',
      );
    }

    final enabled = json['enabled'];
    if (enabled != null && enabled is! bool) {
      errors.add('Pole "enabled" musí byť boolean.');
    }

    for (final key in <String>['description', 'entryPoint']) {
      final value = json[key];
      if (value != null && value is! String) {
        errors.add('Pole "$key" musí byť text.');
      }
    }

    final capabilities = json['capabilities'];
    if (capabilities != null) {
      if (capabilities is! List<dynamic>) {
        errors.add('Pole "capabilities" musí byť zoznam textových hodnôt.');
      } else if (capabilities.any((dynamic value) =>
          value is! String || value.trim().isEmpty)) {
        errors.add('Každá capability musí byť neprázdny text.');
      }
    }

    final permissions = json['permissions'];
    if (permissions != null) {
      if (permissions is! List<dynamic>) {
        errors.add('Pole "permissions" musí byť zoznam textových hodnôt.');
      } else if (permissions.any((dynamic value) =>
          value is! String || value.trim().isEmpty)) {
        errors.add('Každé oprávnenie musí byť neprázdny text.');
      }
    }

    return errors;
  }

  void _requireNonEmptyString(
    Map<String, dynamic> json,
    String key,
    List<String> errors,
  ) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      errors.add('Povinné pole "$key" musí byť neprázdny text.');
    }
  }

  void _requireSemanticVersion(
    Map<String, dynamic> json,
    String key,
    List<String> errors,
  ) {
    final value = json[key];
    if (value is! String ||
        !RegExp(r'^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$')
            .hasMatch(value.trim())) {
      errors.add('Pole "$key" musí obsahovať platnú sémantickú verziu.');
    }
  }
}
