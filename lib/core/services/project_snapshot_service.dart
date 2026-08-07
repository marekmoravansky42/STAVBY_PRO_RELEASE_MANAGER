import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

class ProjectSnapshotInfo {
  const ProjectSnapshotInfo({
    required this.directory,
    required this.projectPath,
    required this.createdAt,
    required this.label,
    required this.fileCount,
  });

  final Directory directory;
  final String projectPath;
  final DateTime createdAt;
  final String label;
  final int fileCount;
}

/// Lightweight local safety snapshots for source workspaces.
///
/// Snapshots are stored next to the workspace under `.release_manager_snapshots`
/// so build/cache directories are never copied recursively into the project.
class ProjectSnapshotService {
  const ProjectSnapshotService();

  static const Set<String> _excludedDirectoryNames = <String>{
    '.git',
    '.dart_tool',
    '.gradle',
    'build',
    'cache',
    'temp',
    'tmp',
    'diagnostics',
  };

  Directory snapshotsRoot(String projectPath) {
    final project = Directory(projectPath);
    final parent = project.parent.path;
    final name = path.basename(project.absolute.path);
    return Directory(path.join(parent, '.release_manager_snapshots', name));
  }

  Future<ProjectSnapshotInfo> createSnapshot(
    String projectPath, {
    String label = 'Before build',
  }) async {
    final source = Directory(projectPath);
    if (!await source.exists()) {
      throw FileSystemException('Workspace neexistuje.', projectPath);
    }

    final now = DateTime.now();
    final stamp = now.toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final safeLabel = label
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final target = Directory(path.join(snapshotsRoot(projectPath).path, '${stamp}_${safeLabel.isEmpty ? 'snapshot' : safeLabel}'));
    await target.create(recursive: true);

    var fileCount = 0;
    await for (final entity in source.list(recursive: true, followLinks: false)) {
      final relative = path.relative(entity.path, from: source.path);
      if (_shouldExclude(relative)) continue;
      final destination = path.join(target.path, 'workspace', relative);
      if (entity is Directory) {
        await Directory(destination).create(recursive: true);
      } else if (entity is File) {
        await Directory(path.dirname(destination)).create(recursive: true);
        await entity.copy(destination);
        fileCount++;
      }
    }

    final manifest = <String, Object?>{
      'format': 1,
      'projectPath': source.absolute.path,
      'projectName': path.basename(source.absolute.path),
      'createdAt': now.toIso8601String(),
      'label': label,
      'fileCount': fileCount,
      'excludedDirectories': _excludedDirectoryNames.toList()..sort(),
    };
    await File(path.join(target.path, 'snapshot.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      flush: true,
    );

    return ProjectSnapshotInfo(
      directory: target,
      projectPath: source.absolute.path,
      createdAt: now,
      label: label,
      fileCount: fileCount,
    );
  }

  Future<void> restoreSnapshot(ProjectSnapshotInfo snapshot) async {
    final source = Directory(path.join(snapshot.directory.path, 'workspace'));
    final target = Directory(snapshot.projectPath);
    if (!await source.exists()) {
      throw FileSystemException('Snapshot neobsahuje workspace.', source.path);
    }
    await target.create(recursive: true);

    await for (final entity in source.list(recursive: true, followLinks: false)) {
      final relative = path.relative(entity.path, from: source.path);
      final destination = path.join(target.path, relative);
      if (entity is Directory) {
        await Directory(destination).create(recursive: true);
      } else if (entity is File) {
        await Directory(path.dirname(destination)).create(recursive: true);
        await entity.copy(destination);
      }
    }
  }

  Future<List<ProjectSnapshotInfo>> listSnapshots(String projectPath) async {
    final root = snapshotsRoot(projectPath);
    if (!await root.exists()) return const <ProjectSnapshotInfo>[];
    final result = <ProjectSnapshotInfo>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final manifestFile = File(path.join(entity.path, 'snapshot.json'));
      if (!await manifestFile.exists()) continue;
      try {
        final decoded = jsonDecode(await manifestFile.readAsString());
        if (decoded is! Map) continue;
        final map = Map<String, Object?>.from(decoded);
        final createdAt = DateTime.tryParse(map['createdAt']?.toString() ?? '');
        if (createdAt == null) continue;
        result.add(ProjectSnapshotInfo(
          directory: entity,
          projectPath: map['projectPath']?.toString() ?? projectPath,
          createdAt: createdAt,
          label: map['label']?.toString() ?? 'Snapshot',
          fileCount: int.tryParse(map['fileCount']?.toString() ?? '') ?? 0,
        ));
      } catch (_) {
        // Ignore incomplete snapshot folders and keep the rest usable.
      }
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  bool _shouldExclude(String relativePath) {
    final segments = path.split(relativePath);
    return segments.any((segment) => _excludedDirectoryNames.contains(segment.toLowerCase())) ||
        segments.contains('.release_manager_snapshots');
  }
}
