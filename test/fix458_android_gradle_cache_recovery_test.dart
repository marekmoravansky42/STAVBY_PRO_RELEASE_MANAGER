import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stavby_pro_release_manager/services/android_gradle_cache_recovery.dart';

void main() {
  test('selects only STAVBY PRO Flutter build processes and their descendants',
      () {
    const workspace = r'C:\SP\STAVBY_PRO';
    const processes = <AndroidGradleProcess>[
      AndroidGradleProcess(
        id: 10,
        parentId: 1,
        name: 'dart.exe',
        commandLine: r'dart flutter_tools.snapshot build apk C:\SP\STAVBY_PRO',
      ),
      AndroidGradleProcess(
        id: 11,
        parentId: 10,
        name: 'java.exe',
        commandLine: 'GradleDaemon',
      ),
      AndroidGradleProcess(
        id: 12,
        parentId: 1,
        name: 'java.exe',
        commandLine: 'Unrelated IDE process',
      ),
    ];

    expect(
      AndroidGradleCacheRecovery.projectBuildProcesses(processes, workspace)
          .map((process) => process.id),
      containsAll(<int>[10, 11]),
    );
    expect(
      AndroidGradleCacheRecovery.projectBuildProcesses(processes, workspace)
          .map((process) => process.id),
      isNot(contains(12)),
    );
  });

  test('removes only android .gradle-release and keeps workspace data',
      () async {
    final root = await Directory.systemTemp.createTemp('fix458_gradle_');
    addTearDown(() => root.delete(recursive: true));
    final cache = Directory(
      path.join(root.path, 'android', '.gradle-release'),
    );
    await cache.create(recursive: true);
    await File(path.join(cache.path, 'lock')).writeAsString('temporary');
    final data = File(path.join(root.path, 'Documents', 'stavby_pro.db'));
    await data.parent.create(recursive: true);
    await data.writeAsString('must remain');

    final stopped = <int>[];
    final result = await AndroidGradleCacheRecovery.prepare(
      workspace: root.path,
      listProcesses: () async => const <AndroidGradleProcess>[
        AndroidGradleProcess(
          id: 77,
          parentId: 1,
          name: 'gradle.bat',
          commandLine: 'placeholder',
        ),
      ],
      stopProcess: (id) async {
        stopped.add(id);
        return true;
      },
    );

    expect(result.status, AndroidGradleCacheRecoveryStatus.recovered);
    expect(await cache.exists(), isFalse);
    expect(await data.readAsString(), 'must remain');
    expect(stopped, isEmpty);
  });

  test('Android APK build stops before Flutter when cache recovery is blocked',
      () {
    final source = File('lib/main.dart').readAsStringSync();
    final recovery = source.indexOf('AndroidGradleCacheRecovery.prepare(');
    final flutter = source.indexOf("final commandText = 'flutter");

    expect(recovery, greaterThanOrEqualTo(0));
    expect(flutter, greaterThan(recovery));
    expect(source, contains('Android APK build sa nespustil.'));
  });

  test('Windows process JSON tolerates a raw command-line control character',
      () {
    final source = '[{"ProcessId":77,"ParentProcessId":1,"Name":"java.exe",'
        '"CommandLine":"C:\\\\SP${String.fromCharCode(7)}STAVBY_PRO"}]';

    final processes =
        AndroidGradleCacheRecovery.decodeWindowsProcessJson(source);

    expect(processes, hasLength(1));
    expect(processes.single.id, 77);
    expect(processes.single.commandLine, contains('STAVBY_PRO'));
  });

  test('accepts only an exact Gradle cleanup lock failure with a new APK',
      () async {
    final root = await Directory.systemTemp.createTemp('fix459_apk_');
    addTearDown(() => root.delete(recursive: true));
    final startedAt = DateTime.now();
    final apk = File(
      path.join(root.path, 'build', 'app', 'outputs', 'flutter-apk',
          'app-release.apk'),
    );
    await apk.parent.create(recursive: true);
    await apk.writeAsBytes(
      <int>[0x50, 0x4b, 0x03, 0x04, ...List.filled(2048, 0)],
    );

    const cleanupFailure = <String>[
      'FAILURE: Build failed with an exception.',
      'Could not stop all services.',
      r'Failed to release lock on C:\workspace\android\.gradle\buildOutputCleanup',
    ];
    expect(
      AndroidGradleCacheRecovery.isExactCleanupLockFailure(cleanupFailure),
      isTrue,
    );
    expect(
      await AndroidGradleCacheRecovery.verifiedCurrentReleaseApk(
        workspace: root.path,
        buildStartedAt: startedAt,
      ),
      isNotNull,
    );
    expect(
      AndroidGradleCacheRecovery.isExactCleanupLockFailure(
        const <String>['Compilation failed.'],
      ),
      isFalse,
    );
  });

  test('Android cleanup-lock fallback is wired only after the Android command',
      () {
    final source = File('lib/main.dart').readAsStringSync();
    final exitCode = source.indexOf('if (exitCode == 0)');
    final fallback = source.indexOf('isExactCleanupLockFailure(');

    expect(fallback, greaterThan(exitCode));
    expect(source, contains('verifiedCurrentReleaseApk('));
  });
}
