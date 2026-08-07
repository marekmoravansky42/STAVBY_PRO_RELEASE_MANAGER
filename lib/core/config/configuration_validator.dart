import 'configuration_keys.dart';

class ConfigurationValidationResult {
  const ConfigurationValidationResult({
    required this.configuration,
    required this.corrections,
  });

  final Map<String, dynamic> configuration;
  final List<String> corrections;

  bool get wasCorrected => corrections.isNotEmpty;
}

class ConfigurationValidator {
  const ConfigurationValidator();

  ConfigurationValidationResult validate(Map<String, dynamic> source) {
    final result = Map<String, dynamic>.from(source);
    final corrections = <String>[];

    _normalizeOptionalDirectory(
      result,
      ConfigurationKeys.managerUpdateDirectory,
      corrections,
    );
    _normalizeOptionalDirectory(
      result,
      ConfigurationKeys.androidReleaseExportDirectory,
      corrections,
    );
    _normalizeOptionalDirectory(
      result,
      ConfigurationKeys.windowsReleaseExportDirectory,
      corrections,
    );
    _normalizeOptionalDirectory(
      result,
      ConfigurationKeys.lastGitWorkspacePath,
      corrections,
    );

    if (result[ConfigurationKeys.darkMode] is! bool) {
      if (result.containsKey(ConfigurationKeys.darkMode)) {
        corrections.add('${ConfigurationKeys.darkMode}: invalid value removed');
      }
      result[ConfigurationKeys.darkMode] = false;
    }

    final recent = result[ConfigurationKeys.recentProjectPaths];
    final normalizedRecent = <String>[];
    if (recent is List) {
      for (final item in recent) {
        final value = item.toString().trim();
        if (value.isEmpty || normalizedRecent.contains(value)) continue;
        normalizedRecent.add(value);
        if (normalizedRecent.length == 6) break;
      }
    } else if (recent != null) {
      corrections.add(
        '${ConfigurationKeys.recentProjectPaths}: invalid value replaced',
      );
    }
    result[ConfigurationKeys.recentProjectPaths] = normalizedRecent;


    final recentGit = result[ConfigurationKeys.recentGitWorkspacePaths];
    final normalizedRecentGit = <String>[];
    if (recentGit is List) {
      for (final item in recentGit) {
        final value = item.toString().trim();
        if (value.isEmpty || normalizedRecentGit.contains(value)) continue;
        normalizedRecentGit.add(value);
        if (normalizedRecentGit.length == 8) break;
      }
    } else if (recentGit != null) {
      corrections.add(
        '${ConfigurationKeys.recentGitWorkspacePaths}: invalid value replaced',
      );
    }
    result[ConfigurationKeys.recentGitWorkspacePaths] = normalizedRecentGit;

    return ConfigurationValidationResult(
      configuration: result,
      corrections: List<String>.unmodifiable(corrections),
    );
  }

  void _normalizeOptionalDirectory(
    Map<String, dynamic> data,
    String key,
    List<String> corrections,
  ) {
    final raw = data[key];
    if (raw == null) return;
    final normalized = raw.toString().trim();
    if (normalized.isEmpty) {
      data.remove(key);
      corrections.add('$key: empty value removed');
      return;
    }
    if (raw is! String || raw != normalized) {
      data[key] = normalized;
      corrections.add('$key: value normalized');
    }
  }
}
