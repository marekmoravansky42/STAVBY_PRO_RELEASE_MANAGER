import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stavby_pro_release_manager/core/projects/project_release_profile.dart';
import 'package:stavby_pro_release_manager/core/projects/project_release_transition_engine.dart';

void main() {
  test('FIX252 engine applies DEV to FINAL only to configuration files', () async {
    final root = await Directory.systemTemp.createTemp('fix252_transition_');
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
      'activeChannel': 'dev',
      'channels': <String, Object?>{
        'dev': <String, Object?>{
          'status': 'DEV',
          'androidApplicationId': 'com.example.stavby_pro.dev',
          'androidLabel': 'STAVBY PRO DEV',
          'dataRootName': 'STAVBY_PRO_DEV',
          'databaseName': 'stavby_pro_dev.db',
        },
        'final': <String, Object?>{
          'status': 'FINAL',
          'androidApplicationId': 'com.example.stavby_pro',
          'androidLabel': 'STAVBY PRO',
          'dataRootName': 'STAVBY_PRO',
          'databaseName': 'stavby_pro.db',
        },
      },
    };
    final profile = ProjectReleaseProfile.fromJson(profileMap);

    await write(
      'release/stavby_pro_release_profile.json',
      '${const JsonEncoder.withIndent('  ').convert(profileMap)}\n',
    );
    await write('lib/core/app/app_environment.dart', """
abstract final class AppEnvironment {
  static const String channel = 'dev';
  static const String androidApplicationId = 'com.example.stavby_pro.dev';
  static const String androidLabel = 'STAVBY PRO DEV';
  static const String dataRootName = 'STAVBY_PRO_DEV';
  static const String databaseName = 'stavby_pro_dev.db';
}
""");
    await write(
      'lib/core/app/app_identity.dart',
      "abstract final class AppIdentity { static const String status = 'DEV'; }\n",
    );
    await write(
      'android/app/build.gradle.kts',
      'applicationId = "com.example.stavby_pro.dev"\nversionCode = 123\n',
    );
    await write(
      'android/app/src/main/AndroidManifest.xml',
      '<application android:label="STAVBY PRO DEV" />\n',
    );

    final dataSentinel = File(path.join(root.path, 'Documents/STAVBY_PRO_DEV/sentinel.txt'));
    await dataSentinel.parent.create(recursive: true);
    await dataSentinel.writeAsString('DO NOT TOUCH');

    
    final windowsMain = File(path.join(root.path, 'windows/runner/main.cpp'));
    await windowsMain.parent.create(recursive: true);
    await windowsMain.writeAsString('''
#include "flutter_window.h"
int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  FlutterWindow window(project);
  if (!window.Create(L"STAVBY PRO DEV", origin, size)) {
    return EXIT_FAILURE;
  }
  return EXIT_SUCCESS;
}
''');

    final windowsRc = File(path.join(root.path, 'windows/runner/Runner.rc'));
    await windowsRc.parent.create(recursive: true);
    await windowsRc.writeAsString(r'''
VS_VERSION_INFO VERSIONINFO
BEGIN
    BLOCK "StringFileInfo"
    BEGIN
        BLOCK "040904e4"
        BEGIN
            VALUE "FileDescription", "STAVBY PRO DEV"
            VALUE "ProductName", "STAVBY PRO DEV"
        END
    END
END
''');

final result = await const ProjectReleaseTransitionEngine().apply(
      workspace: root.path,
      profile: profile,
      targetChannel: 'final',
    );

    expect(result.targetChannel, 'final');
    expect(
      await File(path.join(root.path, 'lib/core/app/app_environment.dart')).readAsString(),
      contains("dataRootName = 'STAVBY_PRO';"),
    );
    expect(
      await File(path.join(root.path, 'android/app/build.gradle.kts')).readAsString(),
      contains('applicationId = "com.example.stavby_pro"'),
    );
    expect(
      await File(path.join(root.path, 'android/app/src/main/AndroidManifest.xml')).readAsString(),
      contains('android:label="STAVBY PRO"'),
    );
    expect(await dataSentinel.readAsString(), 'DO NOT TOUCH');
  });

  test('FIX252 engine is not invoked automatically by FULL BUILD', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('project_release_transition_engine.dart'));
    expect(source, isNot(contains('ProjectReleaseTransitionEngine().apply(')));
  });
}
