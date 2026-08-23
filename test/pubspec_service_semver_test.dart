import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/services/pubspec_service.dart';

void main() {
  Future<void> verifyVersion(String versionLine, String expectedVersion, int expectedBuild) async {
    final Directory dir = await Directory.systemTemp.createTemp('rm_pubspec_semver_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    await File('${dir.path}${Platform.pathSeparator}pubspec.yaml').writeAsString(
      'name: test_project\n$versionLine\n',
    );

    final project = await const PubspecService().readProject(dir.path);
    expect(project.version, expectedVersion);
    expect(project.build, expectedBuild);
  }

  test('reads stable Flutter version', () async {
    await verifyVersion('version: 3.8.91+465', '3.8.91', 465);
  });

  test('reads RC Release Recipe version', () async {
    await verifyVersion('version: 3.8.91-rc.1+465', '3.8.91-rc.1', 465);
  });

  test('reads DEV Release Recipe version', () async {
    await verifyVersion('version: 3.8.91-dev.1+465', '3.8.91-dev.1', 465);
  });
}
