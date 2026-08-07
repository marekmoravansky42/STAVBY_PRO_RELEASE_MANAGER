import 'dart:io';

import 'package:path/path.dart' as path;

import '../release/artifact_definition.dart';

class ArtifactService {
  const ArtifactService();

  Future<Directory> prepareReleaseLayout(String releaseRoot) async {
    final root = Directory(releaseRoot);
    for (final name in const <String>[
      'windows',
      'android',
      'reports',
      'changelog',
      'archive',
    ]) {
      await Directory(path.join(root.path, name)).create(recursive: true);
    }
    return root;
  }

  Future<List<ArtifactResult>> collect({
    required String releaseRoot,
    required List<ArtifactDefinition> artifacts,
  }) async {
    final results = <ArtifactResult>[];
    for (final artifact in artifacts) {
      final source = File(artifact.sourcePath);
      final target = File(path.join(releaseRoot, artifact.relativeTargetPath));
      if (!await source.exists()) {
        if (artifact.required) {
          throw FileSystemException(
            'Povinný artefakt nebol nájdený: ${artifact.id}',
            source.path,
          );
        }
        results.add(ArtifactResult(
          id: artifact.id,
          sourcePath: source.path,
          targetPath: target.path,
          copied: false,
          message: 'Voliteľný artefakt neexistuje.',
        ));
        continue;
      }
      await target.parent.create(recursive: true);
      await source.copy(target.path);
      results.add(ArtifactResult(
        id: artifact.id,
        sourcePath: source.path,
        targetPath: target.path,
        copied: true,
        message: 'Artefakt bol skopírovaný.',
      ));
    }
    return results;
  }

  Future<File> createZip({
    required String sourceDirectory,
    required String archivePath,
  }) async {
    if (!Platform.isWindows) {
      throw UnsupportedError(
        'Automatická ZIP archivácia je v Build 214 podporovaná na Windows.',
      );
    }
    final archive = File(archivePath);
    await archive.parent.create(recursive: true);
    if (await archive.exists()) await archive.delete();

    final escapedSource = sourceDirectory.replaceAll("'", "''");
    final temporaryPath = path.join(archive.parent.parent.path, '.release_archive_${DateTime.now().microsecondsSinceEpoch}.zip');
    final temporaryArchive = File(temporaryPath);
    final escapedArchive = temporaryArchive.path.replaceAll("'", "''");
    final result = await Process.run(
      'powershell',
      <String>[
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        "Compress-Archive -Path '$escapedSource\\*' -DestinationPath '$escapedArchive' -Force",
      ],
      runInShell: true,
    );
    if (result.exitCode != 0 || !await temporaryArchive.exists()) {
      throw ProcessException(
        'powershell',
        const <String>['Compress-Archive'],
        '${result.stdout}\n${result.stderr}'.trim(),
        result.exitCode,
      );
    }
    await temporaryArchive.rename(archive.path);
    return archive;
  }
}
