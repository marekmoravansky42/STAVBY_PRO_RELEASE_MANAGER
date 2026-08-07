import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stavby_pro_release_manager/core/project_workspace/project_platform.dart';
import 'package:stavby_pro_release_manager/core/project_workspace/project_workspace_service.dart';

void main() {
  test('detects only complete Flutter platform projects', () async {
    final root = await Directory.systemTemp.createTemp('rm_workspace_');
    addTearDown(() => root.delete(recursive: true));
    await File(path.join(root.path, 'pubspec.yaml')).writeAsString(
      'name: sample_app\ndependencies:\n  flutter:\n    sdk: flutter\n',
    );

    await Directory(path.join(root.path, 'windows')).create();
    await File(path.join(root.path, 'windows', 'CMakeLists.txt'))
        .writeAsString('cmake_minimum_required(VERSION 3.14)');
    await Directory(path.join(root.path, 'web')).create();
    await File(path.join(root.path, 'web', 'index.html'))
        .writeAsString('<!doctype html>');

    // An empty/partial Android folder must not enable Android builds.
    await Directory(path.join(root.path, 'android')).create(recursive: true);

    final workspace = await const ProjectWorkspaceService().open(root.path);

    expect(workspace.projectName, 'sample_app');
    expect(workspace.platforms, contains(ProjectPlatform.windows));
    expect(workspace.platforms, contains(ProjectPlatform.web));
    expect(workspace.platforms, isNot(contains(ProjectPlatform.android)));
  });

  test('detects Android project with Groovy build file', () async {
    final root = await Directory.systemTemp.createTemp('rm_android_groovy_');
    addTearDown(() => root.delete(recursive: true));
    await File(path.join(root.path, 'pubspec.yaml')).writeAsString(
      'name: sample_app\ndependencies:\n  flutter:\n    sdk: flutter\n',
    );
    await Directory(path.join(root.path, 'android', 'app'))
        .create(recursive: true);
    await File(path.join(root.path, 'android', 'app', 'build.gradle'))
        .writeAsString('plugins {}');

    final workspace = await const ProjectWorkspaceService().open(root.path);
    expect(workspace.platforms, contains(ProjectPlatform.android));
  });

  test('detects Android project with Kotlin build file', () async {
    final root = await Directory.systemTemp.createTemp('rm_android_kotlin_');
    addTearDown(() => root.delete(recursive: true));
    await File(path.join(root.path, 'pubspec.yaml')).writeAsString(
      'name: sample_app\ndependencies:\n  flutter:\n    sdk: flutter\n',
    );
    await Directory(path.join(root.path, 'android', 'app'))
        .create(recursive: true);
    await File(path.join(root.path, 'android', 'app', 'build.gradle.kts'))
        .writeAsString('plugins {}');

    final workspace = await const ProjectWorkspaceService().open(root.path);
    expect(workspace.platforms, contains(ProjectPlatform.android));
  });

  test('rejects directory without pubspec.yaml', () async {
    final root = await Directory.systemTemp.createTemp('rm_invalid_');
    addTearDown(() => root.delete(recursive: true));
    expect(
      () => const ProjectWorkspaceService().open(root.path),
      throwsA(isA<ProjectWorkspaceException>()),
    );
  });
}
