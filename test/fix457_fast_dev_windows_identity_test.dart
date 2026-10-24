import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stavby_pro_release_manager/core/projects/project_release_profile.dart';
import 'package:stavby_pro_release_manager/core/projects/project_release_transition_engine.dart';

void main() {
  test('FAST DEV transition restores the DEV Windows executable identity',
      () async {
    final root = await Directory.systemTemp.createTemp('fix457_fast_dev_');
    addTearDown(() => root.delete(recursive: true));

    Future<void> write(String relative, String text) async {
      final file = File(path.join(root.path, relative));
      await file.parent.create(recursive: true);
      await file.writeAsString(text);
    }

    final profileMap = <String, Object?>{
      'schemaVersion': 1,
      'projectId': 'stavby_pro',
      'displayName': 'STAVBY PRO',
      'identityFile': 'lib/core/app/app_identity.dart',
      'activeChannel': 'final',
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
    await write('lib/core/app/app_identity.dart',
        "static const String status = 'FINAL';\n");
    await write('lib/core/app/app_environment.dart', '''
abstract final class AppEnvironment {
  static const String channel = 'final';
  static const String androidApplicationId = 'com.example.stavby_pro';
  static const String androidLabel = 'STAVBY PRO';
  static const String dataRootName = 'STAVBY_PRO';
  static const String databaseName = 'stavby_pro.db';
}
''');
    await write('android/app/build.gradle.kts',
        'applicationId = "com.example.stavby_pro"\n');
    await write('android/app/src/main/AndroidManifest.xml',
        '<application android:label="STAVBY PRO" />\n');
    await write('windows/runner/main.cpp',
        'window.Create(L"STAVBY PRO", origin, size);\n');
    await write('windows/runner/Runner.rc', '''
VALUE "FileDescription", "STAVBY PRO"
VALUE "ProductName", "STAVBY PRO"
VALUE "InternalName", "stavby_pro"
VALUE "OriginalFilename", "stavby_pro.exe"
''');
    await write('windows/CMakeLists.txt',
        'project(stavby_pro LANGUAGES CXX)\nset(BINARY_NAME "stavby_pro")\n');

    final result = await const ProjectReleaseTransitionEngine().apply(
      workspace: root.path,
      profile: profile,
      targetChannel: 'dev',
    );

    expect(result.targetChannel, 'dev');
    expect(result.changedFiles, contains('windows/CMakeLists.txt'));
    expect(
      await File(path.join(root.path, 'windows/CMakeLists.txt')).readAsString(),
      contains('set(BINARY_NAME "stavby_pro_dev")'),
    );
    expect(
      await File(path.join(root.path, 'windows/runner/Runner.rc'))
          .readAsString(),
      contains('VALUE "OriginalFilename", "stavby_pro_dev.exe"'),
    );
    expect(
      await File(path.join(root.path, ProjectReleaseProfile.relativePath))
          .readAsString(),
      contains('"activeChannel": "dev"'),
    );
  });

  test('FAST DEV BUILD invokes the DEV transition before Flutter build steps',
      () {
    final source = File('lib/main.dart').readAsStringSync();
    final buildMethod = source.indexOf('Future<void> _runOneClickBuild(');
    final transition = source.indexOf("targetChannel: 'dev'", buildMethod);
    final flutterExecution = source.indexOf(
      '_runWorkspaceFlutterStep(',
      transition,
    );

    expect(transition, greaterThanOrEqualTo(0));
    expect(flutterExecution, greaterThan(transition));
  });
}
