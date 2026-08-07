import 'plugin_capabilities.dart';

/// Immutable metadata for a plugin compiled into Release Manager.
class PluginDescriptor {
  const PluginDescriptor({
    required this.id,
    required this.name,
    required this.version,
    required this.minimumHostVersion,
    required this.capabilities,
    this.description = '',
    this.enabledByDefault = true,
  });

  final String id;
  final String name;
  final String version;
  final String minimumHostVersion;
  final Set<PluginCapability> capabilities;
  final String description;
  final bool enabledByDefault;

  List<String> validate() {
    final errors = <String>[];
    if (!_isValidId(id)) {
      errors.add('Plugin ID musí obsahovať iba malé písmená, čísla, bodky, pomlčky alebo podčiarkovníky.');
    }
    if (name.trim().isEmpty) errors.add('Plugin musí mať názov.');
    if (!_SemanticVersion.isValid(version)) errors.add('Verzia pluginu nie je platná: $version.');
    if (!_SemanticVersion.isValid(minimumHostVersion)) {
      errors.add('Minimálna verzia Release Managera nie je platná: $minimumHostVersion.');
    }
    if (capabilities.isEmpty) errors.add('Plugin musí deklarovať aspoň jednu capability.');
    return List<String>.unmodifiable(errors);
  }

  bool supportsHostVersion(String hostVersion) {
    final host = _SemanticVersion.tryParse(hostVersion);
    final minimum = _SemanticVersion.tryParse(minimumHostVersion);
    return host != null && minimum != null && host.compareTo(minimum) >= 0;
  }

  static bool _isValidId(String value) =>
      RegExp(r'^[a-z0-9][a-z0-9._-]*$').hasMatch(value.trim());
}

class _SemanticVersion implements Comparable<_SemanticVersion> {
  const _SemanticVersion(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  static bool isValid(String value) => tryParse(value) != null;

  static _SemanticVersion? tryParse(String value) {
    final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:[-+].*)?$').firstMatch(value.trim());
    if (match == null) return null;
    return _SemanticVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  @override
  int compareTo(_SemanticVersion other) {
    final majorResult = major.compareTo(other.major);
    if (majorResult != 0) return majorResult;
    final minorResult = minor.compareTo(other.minor);
    if (minorResult != 0) return minorResult;
    return patch.compareTo(other.patch);
  }
}
