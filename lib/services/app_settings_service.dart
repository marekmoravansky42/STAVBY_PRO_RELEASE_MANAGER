import '../core/config/configuration_keys.dart';
import '../core/config/configuration_manager.dart';

class AppSettings {
  const AppSettings({
    this.managerUpdateDirectory,
    this.androidReleaseExportDirectory,
    this.windowsReleaseExportDirectory,
    this.darkMode = false,
    this.recentProjectPaths = const <String>[],
    this.lastGitWorkspacePath,
    this.recentGitWorkspacePaths = const <String>[],
    this.lastSelectedPage = 0,
    this.developerMode = false,
  });

  final String? managerUpdateDirectory;
  final String? androidReleaseExportDirectory;
  final String? windowsReleaseExportDirectory;
  final bool darkMode;
  final List<String> recentProjectPaths;
  final String? lastGitWorkspacePath;
  final List<String> recentGitWorkspacePaths;
  final int lastSelectedPage;
  final bool developerMode;
}

class AppSettingsService {
  const AppSettingsService();

  ConfigurationManager get _configuration => ConfigurationManager.instance;

  Future<AppSettings> load() async {
    final data = await _configuration.load();
    return AppSettings(
      managerUpdateDirectory: _optionalString(
        data[ConfigurationKeys.managerUpdateDirectory],
      ),
      androidReleaseExportDirectory: _optionalString(
        data[ConfigurationKeys.androidReleaseExportDirectory],
      ),
      windowsReleaseExportDirectory: _optionalString(
        data[ConfigurationKeys.windowsReleaseExportDirectory],
      ),
      darkMode: data[ConfigurationKeys.darkMode] == true,
      lastGitWorkspacePath: _optionalString(data[ConfigurationKeys.lastGitWorkspacePath]),
      recentGitWorkspacePaths: (data[ConfigurationKeys.recentGitWorkspacePaths] is List)
          ? (data[ConfigurationKeys.recentGitWorkspacePaths] as List)
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .take(8)
              .toList(growable: false)
          : const <String>[],
      lastSelectedPage: data[ConfigurationKeys.lastSelectedPage] is int
          ? data[ConfigurationKeys.lastSelectedPage] as int
          : 0,
      developerMode: data[ConfigurationKeys.developerMode] == true,
      recentProjectPaths: (data[ConfigurationKeys.recentProjectPaths] is List)
          ? (data[ConfigurationKeys.recentProjectPaths] as List)
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .take(6)
              .toList(growable: false)
          : const <String>[],
    );
  }

  Future<void> saveManagerUpdateDirectory(String directory) {
    return _configuration.write(
      ConfigurationKeys.managerUpdateDirectory,
      directory,
    );
  }

  Future<void> clearManagerUpdateDirectory() {
    return _configuration.remove(ConfigurationKeys.managerUpdateDirectory);
  }

  Future<void> saveAndroidReleaseExportDirectory(String directory) {
    return _configuration.write(
      ConfigurationKeys.androidReleaseExportDirectory,
      directory,
    );
  }

  Future<void> saveWindowsReleaseExportDirectory(String directory) {
    return _configuration.write(
      ConfigurationKeys.windowsReleaseExportDirectory,
      directory,
    );
  }

  Future<void> saveDarkMode(bool enabled) {
    return _configuration.write(ConfigurationKeys.darkMode, enabled);
  }



  Future<void> saveNavigationState({
    required int selectedPage,
    required bool developerMode,
  }) async {
    final data = await _configuration.load();
    data[ConfigurationKeys.lastSelectedPage] = selectedPage;
    data[ConfigurationKeys.developerMode] = developerMode;
    await _configuration.save(data);
  }

  Future<void> saveGitWorkspace(String directory, List<String> recentPaths) async {
    final normalized = <String>[];
    for (final item in recentPaths) {
      final value = item.trim();
      if (value.isEmpty || normalized.contains(value)) continue;
      normalized.add(value);
      if (normalized.length == 8) break;
    }
    final data = await _configuration.load();
    data[ConfigurationKeys.lastGitWorkspacePath] = directory.trim();
    data[ConfigurationKeys.recentGitWorkspacePaths] = normalized;
    await _configuration.save(data);
  }

  Future<void> saveRecentGitWorkspacePaths(List<String> recentPaths) {
    return _configuration.write(ConfigurationKeys.recentGitWorkspacePaths, recentPaths);
  }

  Future<void> saveRecentProjectPaths(List<String> projectPaths) async {
    final normalized = <String>[];
    for (final projectPath in projectPaths) {
      final value = projectPath.trim();
      if (value.isEmpty || normalized.contains(value)) continue;
      normalized.add(value);
      if (normalized.length == 6) break;
    }
    await _configuration.write(
      ConfigurationKeys.recentProjectPaths,
      normalized,
    );
  }

  String? _optionalString(Object? value) {
    final normalized = value?.toString().trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
