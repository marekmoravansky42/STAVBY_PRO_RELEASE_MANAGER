import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stavby_pro_release_manager/core/projects/project_release_profile.dart';
import 'package:stavby_pro_release_manager/core/projects/project_release_transition_engine.dart';

void main() {
  test(
    'FIX405 keeps the FINAL Android artifact while workspace returns to DEV',
    () async {
      final root = await Directory.systemTemp.createTemp('fix405_release_');
      addTearDown(() => root.delete(recursive: true));

      Future<void> write(String relative, String contents) async {
        final file = File(path.join(root.path, relative));
        await file.parent.create(recursive: true);
        await file.writeAsString(contents);
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
      await write('lib/core/app/app_environment.dart', '''
abstract final class AppEnvironment {
  static const String channel = 'dev';
  static const String androidApplicationId = 'com.example.stavby_pro.dev';
  static const String androidLabel = 'STAVBY PRO DEV';
  static const String dataRootName = 'STAVBY_PRO_DEV';
  static const String databaseName = 'stavby_pro_dev.db';
}
''');
      await write(
        'lib/core/app/app_identity.dart',
        "abstract final class AppIdentity { static const String status = 'DEV'; }\n",
      );
      await write(
        'android/app/build.gradle.kts',
        'applicationId = "com.example.stavby_pro.dev"\n',
      );
      await write(
        'android/app/src/main/AndroidManifest.xml',
        '<application android:label="STAVBY PRO DEV" />\n',
      );
      await write(
        'windows/CMakeLists.txt',
        'project(stavby_pro_dev LANGUAGES CXX)\n'
            'set(BINARY_NAME "stavby_pro_dev")\n',
      );
      await write(
        'windows/runner/main.cpp',
        'window.Create(L"STAVBY PRO DEV", origin, size)\n',
      );
      await write(
        'windows/runner/Runner.rc',
        'VALUE "FileDescription", "STAVBY PRO DEV"\n'
            'VALUE "ProductName", "STAVBY PRO DEV"\n'
            'VALUE "InternalName", "stavby_pro_dev"\n'
            'VALUE "OriginalFilename", "stavby_pro_dev.exe"\n',
      );

      final engine = const ProjectReleaseTransitionEngine();
      await engine.apply(
        workspace: root.path,
        profile: profile,
        targetChannel: 'final',
      );

      var androidBuildCalls = 0;
      final artifact = File(path.join(
        root.path,
        'build',
        'app',
        'outputs',
        'flutter-apk',
        'app-release.apk',
      ));
      Future<void> fakeAndroidBuild() async {
        androidBuildCalls++;
        await artifact.parent.create(recursive: true);
        final gradle = await File(
          path.join(root.path, 'android', 'app', 'build.gradle.kts'),
        ).readAsString();
        final manifest = await File(path.join(
          root.path,
          'android',
          'app',
          'src',
          'main',
          'AndroidManifest.xml',
        )).readAsString();
        await artifact.writeAsString('$gradle\n$manifest');
      }

      await fakeAndroidBuild();
      await engine.apply(
        workspace: root.path,
        profile: profile,
        targetChannel: 'dev',
      );

      // FIX405 export uses this already-created artifact; no build may run
      // after the FINAL → DEV restore.
      final exportedArtifact = artifact;
      expect(androidBuildCalls, 1);
      expect(await exportedArtifact.readAsString(),
          contains('com.example.stavby_pro'));
      expect(
        await exportedArtifact.readAsString(),
        contains('android:label="STAVBY PRO"'),
      );
      expect(
        await File(path.join(root.path, 'android/app/build.gradle.kts'))
            .readAsString(),
        contains('com.example.stavby_pro.dev'),
      );
      expect(
        await File(path.join(
          root.path,
          'android/app/src/main/AndroidManifest.xml',
        )).readAsString(),
        contains('android:label="STAVBY PRO DEV"'),
      );
    },
  );

  test('FIX405 One Click Release does not rebuild Android after restore', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start =
        source.indexOf('Future<void> _runOneClickReleaseComplete() async');
    final end = source.indexOf('Future<bool> _applyReleaseRecipe', start);
    final block = source.substring(start, end);

    expect(
      block,
      contains('Používam Android Release APK vytvorené '),
    );
    expect(block, isNot(contains('Spúšťam Android Release APK build...')));
  });
}
