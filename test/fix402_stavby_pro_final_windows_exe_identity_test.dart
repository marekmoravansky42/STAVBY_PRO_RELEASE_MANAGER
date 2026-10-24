import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stavby_pro_release_manager/core/projects/project_release_profile.dart';
import 'package:stavby_pro_release_manager/core/projects/project_release_transition_engine.dart';

void main() {
  test('FIX402 FINAL Windows identity and DEV restore preserve data paths',
      () async {
    final root = await Directory.systemTemp.createTemp('fix402_transition_');
    addTearDown(() => root.delete(recursive: true));

    Future<File> write(String relative, String text) async {
      final file = File(path.join(root.path, relative));
      await file.parent.create(recursive: true);
      await file.writeAsString(text);
      return file;
    }

    final profileMap = <String, Object?>{
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
    final profile = ProjectReleaseProfile.fromJson(profileMap);

    await write(
      ProjectReleaseProfile.relativePath,
      '${const JsonEncoder.withIndent('  ').convert(profileMap)}\n',
    );
    await write(
      'lib/core/app/app_identity.dart',
      "abstract final class AppIdentity { static const String fix = 'FIX291'; static const String status = 'DEV'; }\n",
    );
    await write('lib/core/app/app_environment.dart', '''
abstract final class AppEnvironment {
  static const String channel = 'dev';
  static const String androidApplicationId = 'com.example.stavby_pro.dev';
  static const String androidLabel = 'STAVBY PRO DEV';
  static const String dataRootName = 'STAVBY_PRO_DEV';
  static const String databaseName = 'stavby_pro_dev.db';
}
''');
    await write('android/app/build.gradle.kts',
        'applicationId = "com.example.stavby_pro.dev"\n');
    await write('android/app/src/main/AndroidManifest.xml',
        '<application android:label="STAVBY PRO DEV" />\n');
    await write('windows/runner/main.cpp',
        'window.Create(L"STAVBY PRO DEV", origin, size);\n');
    final devRc = '''VALUE "FileDescription", "STAVBY PRO DEV"
VALUE "ProductName", "STAVBY PRO DEV"
VALUE "InternalName", "stavby_pro_dev"
VALUE "OriginalFilename", "stavby_pro_dev.exe"
''';
    await write('windows/runner/Runner.rc', devRc);
    final devCmake = '''project(stavby_pro_dev LANGUAGES CXX)
set(BINARY_NAME "stavby_pro_dev")
''';
    await write('windows/CMakeLists.txt', devCmake);
    await write('pubspec.yaml', 'version: 3.8.108-dev.1+482\n');

    final originals = <String, List<int>>{};
    for (final relative in ProjectReleaseProfile.transitionConfigFiles) {
      originals[relative] =
          await File(path.join(root.path, relative)).readAsBytes();
    }
    final dataSentinel = await write(
      'Documents/STAVBY_PRO_DEV/Database/stavby_pro_dev.db',
      'DEV DATA MUST NOT MOVE',
    );

    await const ProjectReleaseTransitionEngine().apply(
      workspace: root.path,
      profile: profile,
      targetChannel: 'final',
    );

    final finalCmake =
        await File(path.join(root.path, 'windows/CMakeLists.txt'))
            .readAsString();
    final finalRc = await File(path.join(root.path, 'windows/runner/Runner.rc'))
        .readAsString();
    expect(finalCmake, contains('project(stavby_pro LANGUAGES'));
    expect(finalCmake, contains('set(BINARY_NAME "stavby_pro")'));
    expect(finalCmake, isNot(contains('stavby_pro_dev')));
    expect(finalRc, contains('VALUE "InternalName", "stavby_pro"'));
    expect(finalRc, contains('VALUE "OriginalFilename", "stavby_pro.exe"'));
    expect(finalRc, isNot(contains('stavby_pro_dev')));
    expect(
      await File(path.join(root.path, 'lib/core/app/app_identity.dart'))
          .readAsString(),
      allOf(
        contains("static const String fix = 'FIX291';"),
        contains("static const String status = 'FINAL';"),
      ),
    );
    expect(
      await File(path.join(root.path, 'lib/core/app/app_environment.dart'))
          .readAsString(),
      allOf(contains("dataRootName = 'STAVBY_PRO';"),
          contains("databaseName = 'stavby_pro.db';")),
    );
    expect(await dataSentinel.readAsString(), 'DEV DATA MUST NOT MOVE');

    final backup = Directory(path.join(root.path, 'transition-backup'));
    for (final entry in originals.entries) {
      final backupFile = File(path.join(backup.path, entry.key));
      await backupFile.parent.create(recursive: true);
      await backupFile.writeAsBytes(entry.value, flush: true);
    }
    for (final relative in ProjectReleaseProfile.transitionConfigFiles) {
      final backupFile = File(path.join(backup.path, relative));
      await backupFile.copy(path.join(root.path, relative));
    }

    expect(
      await File(path.join(root.path, 'windows/CMakeLists.txt')).readAsBytes(),
      originals['windows/CMakeLists.txt'],
    );
    expect(
      await File(path.join(root.path, 'windows/runner/Runner.rc'))
          .readAsBytes(),
      originals['windows/runner/Runner.rc'],
    );
    expect(await dataSentinel.readAsString(), 'DEV DATA MUST NOT MOVE');
  });
}
