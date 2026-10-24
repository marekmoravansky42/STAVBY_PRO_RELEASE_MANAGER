import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/services/stavby_pro_windows_update_zip_service.dart';

void main() {
  Future<Directory> fakeBundle(Directory root) async {
    final bundle = Directory('${root.path}${Platform.pathSeparator}Release');
    await bundle.create(recursive: true);
    await File('${bundle.path}${Platform.pathSeparator}stavby_pro_dev.exe')
        .writeAsString('dev exe');
    await File('${bundle.path}${Platform.pathSeparator}flutter_windows.dll')
        .writeAsString('flutter dll');
    await File('${bundle.path}${Platform.pathSeparator}native_assets.json')
        .writeAsString('{}');
    await Directory('${bundle.path}${Platform.pathSeparator}data').create();
    await File(
            '${bundle.path}${Platform.pathSeparator}data${Platform.pathSeparator}app.so')
        .writeAsString('data');
    await File('${bundle.path}${Platform.pathSeparator}plugin.dll')
        .writeAsString('native dll');
    return bundle;
  }

  Future<List<String>> zipEntries(File zip) async {
    final destination =
        Directory('${zip.parent.path}${Platform.pathSeparator}unzipped');
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
      entries.add(entity.path
          .substring(destination.path.length + 1)
          .replaceAll('\\', '/'));
    }
    return entries;
  }

  test(
      'FIX415 DEV update ZIP has a root bundle, metadata and no FINAL/APK payload',
      () async {
    final root = await Directory.systemTemp.createTemp('fix415_update_zip_');
    addTearDown(() => root.delete(recursive: true));
    final bundle = await fakeBundle(root);
    await File('${bundle.path}${Platform.pathSeparator}stavby_pro.exe')
        .writeAsString('old final exe');
    final artifact =
        await StavbyProWindowsUpdateZipService().createDevUpdateZip(
      bundleDirectory: bundle,
      exportDirectory: Directory('${root.path}${Platform.pathSeparator}Export'),
      version: '8.0.0',
    );

    expect(artifact.file.path,
        endsWith('STAVBY_PRO_8.0.0_DEV_WINDOWS_UPDATE.zip'));
    expect(artifact.sizeBytes, greaterThan(0));
    expect(artifact.sha256, matches(RegExp(r'^[a-f0-9]{64}$')));
    final metadata = jsonDecode(await artifact.metadataFile.readAsString())
        as Map<String, dynamic>;
    expect(metadata['path'], artifact.file.path);
    expect(metadata['sizeBytes'], artifact.sizeBytes);
    expect(metadata['sha256'], artifact.sha256);
    final entries = await zipEntries(artifact.file);
    expect(
        entries,
        containsAll(<String>[
          'stavby_pro_dev.exe',
          'flutter_windows.dll',
          'native_assets.json',
          'data',
          'data/app.so',
          'plugin.dll',
        ]));
    expect(entries.where((entry) => entry.startsWith('Windows/')), isEmpty);
    expect(entries.where((entry) => entry.endsWith('.apk')), isEmpty);
    expect(entries, isNot(contains('stavby_pro.exe')));
  });

  test('FIX415 rejects an unexpected third STAVBY PRO executable', () async {
    final root =
        await Directory.systemTemp.createTemp('fix415_update_zip_bad_');
    addTearDown(() => root.delete(recursive: true));
    final bundle = await fakeBundle(root);
    await File('${bundle.path}${Platform.pathSeparator}stavby_pro_preview.exe')
        .writeAsString('unexpected exe');
    await expectLater(
      StavbyProWindowsUpdateZipService().createDevUpdateZip(
        bundleDirectory: bundle,
        exportDirectory:
            Directory('${root.path}${Platform.pathSeparator}Export'),
        version: '8.0.0',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('FIX456 accepts the current standard Windows executable name', () async {
    final root = await Directory.systemTemp.createTemp('fix456_standard_exe_');
    addTearDown(() => root.delete(recursive: true));
    final bundle = await fakeBundle(root);
    final devExe =
        File('${bundle.path}${Platform.pathSeparator}stavby_pro_dev.exe');
    await devExe.rename(
      '${bundle.path}${Platform.pathSeparator}stavby_pro.exe',
    );

    final artifact =
        await StavbyProWindowsUpdateZipService().createDevUpdateZip(
      bundleDirectory: bundle,
      exportDirectory: Directory('${root.path}${Platform.pathSeparator}Export'),
      version: '8.0.0',
    );
    final metadata = jsonDecode(await artifact.metadataFile.readAsString())
        as Map<String, dynamic>;
    final entries = await zipEntries(artifact.file);

    expect(metadata['entryExe'], 'stavby_pro.exe');
    expect(entries, contains('stavby_pro.exe'));
    expect(entries, isNot(contains('stavby_pro_dev.exe')));
  });

  test('FIX415 rejects an Android APK mixed into the DEV bundle', () async {
    final root =
        await Directory.systemTemp.createTemp('fix415_update_zip_apk_');
    addTearDown(() => root.delete(recursive: true));
    final bundle = await fakeBundle(root);
    await File('${bundle.path}${Platform.pathSeparator}app-release.apk')
        .writeAsString('apk');

    await expectLater(
      StavbyProWindowsUpdateZipService().createDevUpdateZip(
        bundleDirectory: bundle,
        exportDirectory:
            Directory('${root.path}${Platform.pathSeparator}Export'),
        version: '8.0.0',
      ),
      throwsA(isA<StateError>()),
    );
  });
}
