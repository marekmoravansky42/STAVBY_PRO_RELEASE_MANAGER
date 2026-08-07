import 'plugin_permission.dart';

class PluginPermissionValidationResult {
  const PluginPermissionValidationResult({
    required this.permissions,
    required this.errors,
  });

  final Set<PluginPermission> permissions;
  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

class PluginPermissionValidator {
  const PluginPermissionValidator();

  PluginPermissionValidationResult validate(Iterable<String> values) {
    final permissions = <PluginPermission>{};
    final errors = <String>[];

    for (final rawValue in values) {
      final value = rawValue.trim();
      final permission = PluginPermissionWireName.tryParse(value);
      if (permission == null) {
        errors.add('Neznáme oprávnenie pluginu: "$value".');
      } else if (!permissions.add(permission)) {
        errors.add('Duplicitné oprávnenie pluginu: "$value".');
      }
    }

    return PluginPermissionValidationResult(
      permissions: Set<PluginPermission>.unmodifiable(permissions),
      errors: List<String>.unmodifiable(errors),
    );
  }
}
