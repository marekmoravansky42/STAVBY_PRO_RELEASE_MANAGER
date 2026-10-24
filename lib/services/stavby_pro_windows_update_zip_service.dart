import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

class StavbyProWindowsUpdateZipArtifact {
  const StavbyProWindowsUpdateZipArtifact({
    required this.file,
    required this.metadataFile,
    required this.sizeBytes,
    required this.sha256,
  });

  final File file;
  final File metadataFile;
  final int sizeBytes;
  final String sha256;
}

/// Creates the updater payload expected by STAVBY PRO's Windows in-app update.
///
/// The archive contains the runner/Release bundle directly at its root. It is
/// deliberately separate from the combined distribution archive, which can
/// contain platform folders and an Android APK.
class StavbyProWindowsUpdateZipService {
  static const String expectedExeName = 'stavby_pro_dev.exe';
  static const String standardExeName = 'stavby_pro.exe';

  Future<StavbyProWindowsUpdateZipArtifact> createDevUpdateZip({
    required Directory bundleDirectory,
    required Directory exportDirectory,
    required String version,
  }) async {
    await exportDirectory.create(recursive: true);

    final zip = File(
      path.join(
        exportDirectory.path,
        'STAVBY_PRO_${version}_DEV_WINDOWS_UPDATE.zip',
      ),
    );
    final staging = Directory(
      path.join(
          exportDirectory.path, '.STAVBY_PRO_${version}_DEV_UPDATE_STAGING'),
    );
    if (await staging.exists()) await staging.delete(recursive: true);
    await staging.create(recursive: true);

    try {
      final entryExe = await copyValidatedDevBundle(
        bundleDirectory: bundleDirectory,
        targetDirectory: staging,
      );
      if (await zip.exists()) await zip.delete();
      await _compressRoot(staging, zip);
      if (!await zip.exists()) {
        throw StateError('Windows update ZIP nebol vytvorený: ${zip.path}');
      }
      final sizeBytes = await zip.length();
      if (sizeBytes <= 0) {
        throw StateError('Windows update ZIP je prázdny: ${zip.path}');
      }
      final sha = (await sha256.bind(zip.openRead()).first).toString();
      final metadata = File('${zip.path}.json');
      await metadata.writeAsString(
        const JsonEncoder.withIndent('  ').convert(<String, Object?>{
          'kind': 'stavbyProWindowsDevUpdateZip',
          'path': zip.path,
          'sizeBytes': sizeBytes,
          'sha256': sha,
          'version': version,
          'stage': 'DEV',
          'entryExe': entryExe,
        }),
        flush: true,
      );
      return StavbyProWindowsUpdateZipArtifact(
        file: zip,
        metadataFile: metadata,
        sizeBytes: sizeBytes,
        sha256: sha,
      );
    } finally {
      if (await staging.exists()) await staging.delete(recursive: true);
    }
  }

  /// Copies only the current DEV Windows runtime payload.
  ///
  /// Older bundles use [expectedExeName]; current Flutter Windows bundles use
  /// [standardExeName]. When both exist, the explicit DEV executable wins and
  /// the standard one is excluded. Any third STAVBY PRO executable remains a
  /// safety error.
  Future<String> copyValidatedDevBundle({
    required Directory bundleDirectory,
    required Directory targetDirectory,
  }) async {
    final entryExe = await _verifyBundle(bundleDirectory);
    await targetDirectory.create(recursive: true);
    await _copyBundle(bundleDirectory, targetDirectory, entryExe);
    return entryExe;
  }

  Future<String> _verifyBundle(Directory bundle) async {
    if (!await bundle.exists()) {
      throw StateError('Windows Release bundle neexistuje: ${bundle.path}');
    }
    final devExe = File(path.join(bundle.path, expectedExeName));
    final standardExe = File(path.join(bundle.path, standardExeName));
    final entryExe = await devExe.exists()
        ? expectedExeName
        : await standardExe.exists()
            ? standardExeName
            : null;
    if (entryExe == null) {
      throw StateError(
        'Windows Release bundle nemá $expectedExeName ani $standardExeName.',
      );
    }
    for (final requiredPath in <String>[
      'flutter_windows.dll',
      'native_assets.json',
    ]) {
      if (!await File(path.join(bundle.path, requiredPath)).exists()) {
        throw StateError('Windows Release bundle nemá $requiredPath.');
      }
    }
    if (!await Directory(path.join(bundle.path, 'data')).exists()) {
      throw StateError('Windows Release bundle nemá priečinok data.');
    }

    await for (final entity
        in bundle.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final name = path.basename(entity.path).toLowerCase();
      if (name.endsWith('.apk')) {
        throw StateError(
            'Windows update bundle nesmie obsahovať Android APK: ${entity.path}');
      }
      if (name.startsWith('stavby_pro') &&
          name.endsWith('.exe') &&
          name != expectedExeName &&
          name != standardExeName) {
        throw StateError(
            'Windows update bundle obsahuje cudzie STAVBY PRO EXE: ${entity.path}');
      }
    }
    return entryExe;
  }

  Future<void> _copyBundle(
    Directory source,
    Directory target,
    String entryExe,
  ) async {
    await for (final entity in source.list(followLinks: false)) {
      final name = path.basename(entity.path);
      final lowerName = name.toLowerCase();
      if (entity is Directory) {
        if (lowerName == 'data') {
          await _copyDirectory(entity, Directory(path.join(target.path, name)));
        }
        continue;
      }
      if (entity is! File) continue;

      final allowed = lowerName == entryExe ||
          lowerName == 'flutter_windows.dll' ||
          lowerName == 'native_assets.json' ||
          lowerName.endsWith('.dll');
      if (!allowed) continue;
      await entity.copy(path.join(target.path, name));
    }
  }

  Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entity
        in source.list(recursive: false, followLinks: false)) {
      final destination = path.join(target.path, path.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(destination));
      } else if (entity is File) {
        await entity.copy(destination);
      }
    }
  }

  Future<void> _compressRoot(Directory source, File target) async {
    final escapedSource = source.path.replaceAll("'", "''");
    final escapedTarget = target.path.replaceAll("'", "''");
    final result = await Process.run(
      'powershell.exe',
      <String>[
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        "Add-Type -AssemblyName System.IO.Compression.FileSystem; "
            "[IO.Compression.ZipFile]::CreateFromDirectory('$escapedSource', '$escapedTarget')",
      ],
      runInShell: false,
    );
    if (result.exitCode != 0) {
      throw StateError(
          'Windows update ZIP sa nepodarilo vytvoriť: ${result.stderr}');
    }
  }
}
