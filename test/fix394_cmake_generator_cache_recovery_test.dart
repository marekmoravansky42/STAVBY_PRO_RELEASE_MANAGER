import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stavby_pro_release_manager/services/windows_cmake_generator_cache_recovery.dart';

const _generatorConflict = <String>[
  'CMake Error: Error: generator : Visual Studio 17 2022',
  'Does not match the generator used previously: Visual Studio 18 2026',
  'Either remove the CMakeCache.txt file and CMakeFiles directory',
];

Future<Directory> _workspace(Directory root, {String? cacheHome}) async {
  final workspace = Directory(path.join(root.path, 'workspace'));
  final windows = Directory(path.join(workspace.path, 'windows'));
  final binary = Directory(path.join(workspace.path, 'build', 'windows', 'x64'));
  await windows.create(recursive: true);
  await Directory(path.join(binary.path, 'CMakeFiles')).create(recursive: true);
  await File(path.join(binary.path, 'CMakeCache.txt')).writeAsString(
    'CMAKE_HOME_DIRECTORY:INTERNAL=${cacheHome ?? windows.path}\n',
  );
  return workspace;
}

void main() {
  test('exact generator conflict removes only verified cache and retries once',
      () async {
    final root = await Directory.systemTemp.createTemp('fix394_');
    addTearDown(() => root.delete(recursive: true));
    final workspace = await _workspace(root);
    final outside = File(path.join(root.path, 'outside.txt'));
    await outside.writeAsString('keep');
    var calls = 0;

    final result = await WindowsCmakeGeneratorCacheRecovery.runWithSingleRecovery(
      workspace: workspace.path,
      runBuild: () async {
        calls++;
        return calls == 1
            ? const CmakeBuildCommandResult(1, _generatorConflict)
            : const CmakeBuildCommandResult(0, <String>['build passed']);
      },
    );

    expect(calls, 2);
    expect(result.retried, isTrue);
    expect(result.result.succeeded, isTrue);
    expect(await File(path.join(workspace.path, 'build', 'windows', 'x64', 'CMakeCache.txt')).exists(), isFalse);
    expect(await Directory(path.join(workspace.path, 'build', 'windows', 'x64', 'CMakeFiles')).exists(), isFalse);
    expect(await outside.exists(), isTrue);
  });

  test('other CMake error never removes cache or retries', () async {
    final root = await Directory.systemTemp.createTemp('fix394_');
    addTearDown(() => root.delete(recursive: true));
    final workspace = await _workspace(root);
    var calls = 0;
    final result = await WindowsCmakeGeneratorCacheRecovery.runWithSingleRecovery(
      workspace: workspace.path,
      runBuild: () async => CmakeBuildCommandResult(1, <String>['CMake error: missing SDK ${++calls}']),
    );
    expect(calls, 1);
    expect(result.retried, isFalse);
    expect(await File(path.join(workspace.path, 'build', 'windows', 'x64', 'CMakeCache.txt')).exists(), isTrue);
  });

  test('foreign or outside cache is never removed or retried', () async {
    final root = await Directory.systemTemp.createTemp('fix394_');
    addTearDown(() => root.delete(recursive: true));
    final foreignHome = path.join(root.path, 'foreign', 'windows');
    final workspace = await _workspace(root, cacheHome: foreignHome);
    final outsideCache = File(path.join(workspace.path, 'build', 'windows', 'other', 'CMakeCache.txt'));
    await outsideCache.parent.create(recursive: true);
    await outsideCache.writeAsString('outside');
    var calls = 0;
    final result = await WindowsCmakeGeneratorCacheRecovery.runWithSingleRecovery(
      workspace: workspace.path,
      runBuild: () async => CmakeBuildCommandResult(1, <String>[..._generatorConflict, 'call ${++calls}']),
    );
    expect(calls, 1);
    expect(result.retried, isFalse);
    expect(result.recovery.status, WindowsCmakeCacheRecoveryStatus.unsafe);
    expect(await File(path.join(workspace.path, 'build', 'windows', 'x64', 'CMakeCache.txt')).exists(), isTrue);
    expect(await outsideCache.exists(), isTrue);
  });
}
