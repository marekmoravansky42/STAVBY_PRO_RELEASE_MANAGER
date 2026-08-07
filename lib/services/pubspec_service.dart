import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/project_info.dart';

class PubspecService {
  const PubspecService();

  Future<ProjectInfo> readProject(String projectPath) async {
    final pubspec = File(p.join(projectPath, 'pubspec.yaml'));
    if (!await pubspec.exists()) {
      throw const FormatException('Vo vybranom priečinku nebol nájdený pubspec.yaml.');
    }

    final content = await pubspec.readAsString();
    final nameMatch = RegExp(r'^name:\s*([^\s#]+)', multiLine: true).firstMatch(content);
    final versionMatch = RegExp(
      r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$',
      multiLine: true,
    ).firstMatch(content);

    if (nameMatch == null) {
      throw const FormatException('V pubspec.yaml chýba platný riadok name:.');
    }
    if (versionMatch == null) {
      throw const FormatException(
        'V pubspec.yaml chýba verzia vo formáte version: 1.2.3+4.',
      );
    }

    return ProjectInfo(
      projectName: nameMatch.group(1)!,
      projectPath: projectPath,
      version: versionMatch.group(1)!,
      build: int.parse(versionMatch.group(2)!),
    );
  }

  Future<String> updateVersion({
    required ProjectInfo project,
    required String newVersion,
    required int newBuild,
  }) async {
    if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(newVersion)) {
      throw const FormatException('Verzia musí mať formát napríklad 3.6.0.');
    }
    if (newBuild <= 0) {
      throw const FormatException('Build musí byť celé číslo väčšie ako nula.');
    }

    final pubspec = File(p.join(project.projectPath, 'pubspec.yaml'));
    final backup = File(p.join(project.projectPath, 'pubspec.yaml.bak'));
    final original = await pubspec.readAsString();

    final versionPattern = RegExp(r'^version:\s*.*$', multiLine: true);
    if (!versionPattern.hasMatch(original)) {
      throw const FormatException('Riadok version: sa v pubspec.yaml nenašiel.');
    }

    await pubspec.copy(backup.path);
    final updated = original.replaceFirst(
      versionPattern,
      'version: $newVersion+$newBuild',
    );
    await pubspec.writeAsString(updated, flush: true);
    return backup.path;
  }
}
