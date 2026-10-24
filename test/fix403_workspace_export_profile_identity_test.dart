import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stavby_pro_release_manager/core/projects/project_release_profile.dart';
import 'package:stavby_pro_release_manager/services/workspace_export_identity.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('fix403_export_identity_');
  });

  tearDown(() async => root.delete(recursive: true));

  Future<File> write(String relative, String source) async {
    final file = File(path.join(root.path, relative));
    await file.parent.create(recursive: true);
    await file.writeAsString(source);
    return file;
  }

  Future<File> writeStavbyProfile() {
    final profile = <String, Object?>{
      'schemaVersion': 1,
      'projectId': 'stavby_pro',
      'displayName': 'STAVBY PRO',
      'identityFile': 'lib/core/app/app_identity.dart',
      'activeChannel': 'dev',
      'channels': <String, Object?>{
        'dev': <String, Object?>{
          'status': 'DEV',
          'androidApplicationId': 'com.example.stavby_pro.dev',
          'androidLabel': 'STAVBY PRO DEV',
          'dataRootName': 'STAVBY_PRO_DEV',
          'databaseName': 'stavby_pro_dev.db',
          'windowsBinaryName': 'stavby_pro_dev',
        },
        'final': <String, Object?>{
          'status': 'FINAL',
          'androidApplicationId': 'com.example.stavby_pro',
          'androidLabel': 'STAVBY PRO',
          'dataRootName': 'STAVBY_PRO',
          'databaseName': 'stavby_pro.db',
          'windowsBinaryName': 'stavby_pro',
        },
      },
    };
    return write(
      ProjectReleaseProfile.relativePath,
      '${const JsonEncoder.withIndent('  ').convert(profile)}\n',
    );
  }

  test('FIX403 Release Manager keeps app_version stage identity', () async {
    await write(
      'lib/app/app_version.dart',
      "static const String stage = 'RC1 DEV015 FIX403';\n",
    );

    expect(await readWorkspaceExportFix(root.path), '_FIX403');
  });

  test('FIX403 STAVBY profile reads its declared AppIdentity fix', () async {
    await writeStavbyProfile();
    await write(
      'lib/core/app/app_identity.dart',
      "abstract final class AppIdentity {\n"
          "  static const String fix = 'FIX291';\n"
          "  static const String status = 'DEV';\n"
          "}\n",
    );
    await write(
      'lib/app/app_version.dart',
      "static const String stage = 'RC1 DEV015 FIX403';\n",
    );

    expect(await readWorkspaceExportFix(root.path), '_FIX291');
  });

  test('FIX403 invalid STAVBY fix never falls back to sync history', () async {
    await writeStavbyProfile();
    await write(
      '.release_manager/last_sync.json',
      '{"zipName":"STAVBY_PRO_3.8.108_FINAL_BUILD_482_FIX291.zip"}',
    );
    final identity = await write(
      'lib/core/app/app_identity.dart',
      "abstract final class AppIdentity { static const String status = 'DEV'; }\n",
    );

    for (final source in <String>[
      "abstract final class AppIdentity { static const String status = 'DEV'; }\n",
      "abstract final class AppIdentity { static const String fix = '291'; }\n",
      "static const String fix = 'FIX291';\n"
          "static const String fix = 'FIX290';\n",
    ]) {
      await identity.writeAsString(source);
      await expectLater(readWorkspaceExportFix(root.path), throwsStateError);
    }
  });
}
