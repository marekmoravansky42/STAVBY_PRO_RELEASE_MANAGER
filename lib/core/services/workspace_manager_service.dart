import 'dart:convert';
import 'dart:io';

import '../projects/project_profile.dart';

class WorkspaceHealthItem {
  const WorkspaceHealthItem({required this.name, required this.path, required this.ok});
  final String name;
  final String path;
  final bool ok;
}

class WorkspaceManagerService {
  const WorkspaceManagerService();

  static const List<String> managedDirectories = <String>[
    'Builds',
    'Exports',
    'Profiles',
    'Backups',
    'Logs',
    'Temp',
    'Cache',
    'Artifacts',
  ];

  String managerRoot(String projectPath) =>
      '$projectPath${Platform.pathSeparator}.release_manager';

  Future<List<WorkspaceHealthItem>> health(String projectPath) async {
    final root = managerRoot(projectPath);
    final result = <WorkspaceHealthItem>[
      WorkspaceHealthItem(
        name: 'Flutter projekt',
        path: projectPath,
        ok: await File('$projectPath${Platform.pathSeparator}pubspec.yaml').exists(),
      ),
      WorkspaceHealthItem(
        name: 'Git',
        path: '$projectPath${Platform.pathSeparator}.git',
        ok: await Directory('$projectPath${Platform.pathSeparator}.git').exists(),
      ),
    ];
    for (final name in managedDirectories) {
      final dir = '$root${Platform.pathSeparator}$name';
      result.add(WorkspaceHealthItem(name: name, path: dir, ok: await Directory(dir).exists()));
    }
    return result;
  }

  Future<void> repair(String projectPath) async {
    final root = managerRoot(projectPath);
    await Directory(root).create(recursive: true);
    for (final name in managedDirectories) {
      await Directory('$root${Platform.pathSeparator}$name').create(recursive: true);
    }
  }

  Future<void> exportBundle({
    required String destinationPath,
    required List<ProjectProfile> profiles,
    required String? activeProfileId,
  }) async {
    final file = File(destinationPath);
    await file.parent.create(recursive: true);
    final data = <String, Object?>{
      'format': 'STAVBY_PRO_RELEASE_MANAGER_WORKSPACE',
      'formatVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'activeProfileId': activeProfileId,
      'profiles': profiles.map((profile) => profile.toJson()).toList(growable: false),
    };
    await file.writeAsString('${const JsonEncoder.withIndent('  ').convert(data)}\n', flush: true);
  }

  Future<({List<ProjectProfile> profiles, String? activeProfileId})> importBundle(
    String sourcePath,
  ) async {
    final decoded = jsonDecode(await File(sourcePath).readAsString());
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != 'STAVBY_PRO_RELEASE_MANAGER_WORKSPACE') {
      throw const FormatException('Neplatný .rmworkspace súbor.');
    }
    final rawProfiles = decoded['profiles'];
    if (rawProfiles is! List) {
      throw const FormatException('Workspace neobsahuje Project Profiles.');
    }
    final profiles = <ProjectProfile>[];
    for (final item in rawProfiles) {
      if (item is Map) {
        profiles.add(ProjectProfile.fromJson(Map<String, Object?>.from(item)));
      }
    }
    return (
      profiles: List<ProjectProfile>.unmodifiable(profiles),
      activeProfileId: decoded['activeProfileId'] as String?,
    );
  }
}
