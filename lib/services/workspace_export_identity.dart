import 'dart:io';

import 'package:path/path.dart' as path;

import '../core/projects/project_release_profile.dart';

/// Reads the target workspace, never the running manager or sync history.
Future<String> readWorkspaceExportFix(String projectPath) async {
  final ProjectReleaseProfile? profile;
  try {
    profile = await ProjectReleaseProfile.tryLoad(projectPath);
  } catch (error) {
    throw StateError(
      'Export zastavený: nemožno načítať release profil workspace: $error',
    );
  }
  if (profile != null) {
    return _readProfileWorkspaceExportFix(projectPath, profile);
  }
  return _readReleaseManagerExportFix(projectPath);
}

Future<String> _readReleaseManagerExportFix(String projectPath) async {
  final file = File(path.join(projectPath, 'lib', 'app', 'app_version.dart'));
  final String source;
  try {
    source = await file.readAsString();
  } on FileSystemException catch (error) {
    throw StateError('Export zastavený: nemožno načítať centrálnu identitu '
        '${file.path}: ${error.message}');
  }
  final stages = RegExp(
    r'''^\s*static\s+const\s+String\s+stage\s*=\s*(['"])([^'"\r\n]+)\1\s*;\s*$''',
    multiLine: true,
  ).allMatches(source).toList();
  final fixes = stages.length == 1
      ? RegExp(r'\bFIX([0-9]+)\b').allMatches(stages.single.group(2)!).toList()
      : <RegExpMatch>[];
  if (fixes.length != 1) {
    throw StateError('Export zastavený: centrálna identita ${file.path} '
        'neobsahuje jednoznačné označenie FIX v stage.');
  }
  return '_FIX${fixes.single.group(1)}';
}

Future<String> _readProfileWorkspaceExportFix(
  String projectPath,
  ProjectReleaseProfile profile,
) async {
  final identityPath = profile.identityFile;
  if (path.isAbsolute(identityPath)) {
    throw StateError(
      'Export zastavený: release profil obsahuje neplatnú absolútnu cestu '
      'identityFile: $identityPath',
    );
  }
  final file = File(path.join(projectPath, identityPath));
  final String source;
  try {
    source = await file.readAsString();
  } on FileSystemException catch (error) {
    throw StateError('Export zastavený: nemožno načítať centrálnu identitu '
        '${file.path}: ${error.message}');
  }
  final fixes = RegExp(
    r'''^\s*static\s+const\s+String\s+fix\s*=\s*(['"])(FIX[0-9]+)\1\s*;\s*$''',
    multiLine: true,
  ).allMatches(source).toList();
  if (fixes.length != 1) {
    throw StateError('Export zastavený: centrálna identita ${file.path} '
        'neobsahuje jednu jednoznačnú konštantu fix vo formáte FIX###.');
  }
  return '_${fixes.single.group(2)}';
}
