import 'dart:io';

import 'package:path/path.dart' as path;

import 'project_platform.dart';
import 'project_workspace.dart';

class ProjectWorkspaceException implements Exception {
  const ProjectWorkspaceException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ProjectWorkspaceService {
  const ProjectWorkspaceService();

  Future<ProjectWorkspace> open(String selectedPath) async {
    final root = Directory(path.normalize(path.absolute(selectedPath)));
    if (!await root.exists()) {
      throw const ProjectWorkspaceException('Vybraný priečinok neexistuje.');
    }

    final pubspec = File(path.join(root.path, 'pubspec.yaml'));
    if (!await pubspec.exists()) {
      throw const ProjectWorkspaceException(
        'Vybraný priečinok nie je Flutter projekt: chýba pubspec.yaml.',
      );
    }

    final content = await pubspec.readAsString();
    if (!RegExp(r'^\s*flutter\s*:', multiLine: true).hasMatch(content)) {
      throw const ProjectWorkspaceException(
        'pubspec.yaml neobsahuje Flutter SDK konfiguráciu.',
      );
    }

    final nameMatch = RegExp(r'^\s*name\s*:\s*([^\s#]+)', multiLine: true)
        .firstMatch(content);
    final platforms = await _detectPlatforms(root.path);

    return ProjectWorkspace(
      rootPath: root.path,
      projectName: nameMatch?.group(1) ?? path.basename(root.path),
      platforms: Set<ProjectPlatform>.unmodifiable(platforms),
    );
  }

  /// Detects only complete platform projects, not leftover/empty directories.
  ///
  /// Flutter projects can contain a platform directory that was partially
  /// deleted or copied without its build files. Such a directory must not make
  /// the pipeline attempt a build for that platform.
  Future<Set<ProjectPlatform>> _detectPlatforms(String rootPath) async {
    final detected = <ProjectPlatform>{};

    if (await _hasFile(rootPath, 'windows', 'CMakeLists.txt')) {
      detected.add(ProjectPlatform.windows);
    }
    if (await _hasAnyFile(rootPath, const <List<String>>[
      <String>['android', 'app', 'build.gradle'],
      <String>['android', 'app', 'build.gradle.kts'],
    ])) {
      detected.add(ProjectPlatform.android);
    }
    if (await _hasFile(rootPath, 'web', 'index.html')) {
      detected.add(ProjectPlatform.web);
    }
    if (await _hasFile(rootPath, 'linux', 'CMakeLists.txt')) {
      detected.add(ProjectPlatform.linux);
    }
    if (await _hasFile(
      rootPath,
      'macos',
      'Runner.xcodeproj',
      'project.pbxproj',
    )) {
      detected.add(ProjectPlatform.macos);
    }
    if (await _hasFile(
      rootPath,
      'ios',
      'Runner.xcodeproj',
      'project.pbxproj',
    )) {
      detected.add(ProjectPlatform.ios);
    }

    return detected;
  }

  Future<bool> _hasFile(
    String rootPath,
    String first, [
    String? second,
    String? third,
  ]) {
    final segments = <String>[rootPath, first];
    if (second != null) {
      segments.add(second);
    }
    if (third != null) {
      segments.add(third);
    }
    return File(path.joinAll(segments)).exists();
  }

  Future<bool> _hasAnyFile(
    String rootPath,
    List<List<String>> candidates,
  ) async {
    for (final candidate in candidates) {
      if (await File(path.joinAll(<String>[rootPath, ...candidate])).exists()) {
        return true;
      }
    }
    return false;
  }
}
