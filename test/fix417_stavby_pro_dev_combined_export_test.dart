import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stavby_pro_release_manager/services/stavby_pro_windows_update_zip_service.dart';

void main() {
  Future<Directory> fakeDevBundle(Directory root) async {
    final bundle = Directory(path.join(root.path, 'Release'));
    await bundle.create(recursive: true);
    await File(path.join(bundle.path, 'stavby_pro_dev.exe'))
        .writeAsString('dev');
    await File(path.join(bundle.path, 'stavby_pro.exe'))
        .writeAsString('stale final');
    await File(path.join(bundle.path, 'flutter_windows.dll'))
        .writeAsString('flutter');
    await File(path.join(bundle.path, 'native_assets.json'))
        .writeAsString('{}');
    await Directory(path.join(bundle.path, 'data')).create();
    await File(path.join(bundle.path, 'data', 'asset')).writeAsString('asset');
    await File(path.join(bundle.path, 'plugin.dll')).writeAsString('dll');
    return bundle;
  }

  Future<List<String>> zipEntries(File zip, Directory destination) async {
    final command = "Add-Type -AssemblyName System.IO.Compression.FileSystem; "
        "[IO.Compression.ZipFile]::ExtractToDirectory('${zip.path.replaceAll("'", "''")}', "
        "'${destination.path.replaceAll("'", "''")}')";
    final result = await Process.run('powershell.exe', <String>[
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      command,
    ]);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    final entries = <String>[];
    await for (final entity in destination.list(recursive: true)) {
      entries.add(path
          .relative(entity.path, from: destination.path)
          .replaceAll('\\', '/'));
    }
    return entries;
  }

  test(
      'FIX417 DEV combined ZIP keeps current Windows bundle and excludes stale FINAL exe',
      () async {
    final root = await Directory.systemTemp.createTemp('fix417_combined_');
    addTearDown(() => root.delete(recursive: true));
    final bundle = await fakeDevBundle(root);
    final staging = Directory(path.join(root.path, 'staging'));
    final windows = Directory(path.join(staging.path, 'Windows'));
    await StavbyProWindowsUpdateZipService().copyValidatedDevBundle(
      bundleDirectory: bundle,
      targetDirectory: windows,
    );
    await Directory(path.join(staging.path, 'Android')).create(recursive: true);
    await File(path.join(staging.path, 'Android', 'app-release.apk'))
        .writeAsString('apk');
    final zip = File(path.join(root.path, 'combined.zip'));
    final command = "Add-Type -AssemblyName System.IO.Compression.FileSystem; "
        "[IO.Compression.ZipFile]::CreateFromDirectory('${staging.path.replaceAll("'", "''")}', "
        "'${zip.path.replaceAll("'", "''")}')";
    final result = await Process.run('powershell.exe', <String>[
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      command,
    ]);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    final entries =
        await zipEntries(zip, Directory(path.join(root.path, 'unzipped')));
    expect(entries, contains('Windows/stavby_pro_dev.exe'));
    expect(entries, contains('Windows/native_assets.json'));
    expect(entries, contains('Windows/data/asset'));
    expect(entries, contains('Android/app-release.apk'));
    expect(entries, isNot(contains('Windows/stavby_pro.exe')));
  });

  test(
      'FIX417 blocks unknown third STAVBY PRO executable while FINAL stays outside DEV filter',
      () async {
    final root = await Directory.systemTemp.createTemp('fix417_unknown_');
    addTearDown(() => root.delete(recursive: true));
    final bundle = await fakeDevBundle(root);
    await File(path.join(bundle.path, 'stavby_pro_preview.exe'))
        .writeAsString('unknown');
    await expectLater(
      StavbyProWindowsUpdateZipService().copyValidatedDevBundle(
        bundleDirectory: bundle,
        targetDirectory: Directory(path.join(root.path, 'Windows')),
      ),
      throwsA(isA<StateError>()),
    );
    expect(
        await File(path.join(bundle.path, 'stavby_pro.exe')).exists(), isTrue);
  });
}
