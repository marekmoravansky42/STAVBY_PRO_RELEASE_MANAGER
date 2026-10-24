import 'dart:io';

import 'package:path/path.dart' as path;

class CmakeBuildCommandResult {
  const CmakeBuildCommandResult(this.exitCode, this.output);

  final int exitCode;
  final List<String> output;
  bool get succeeded => exitCode == 0;
}

enum WindowsCmakeCacheRecoveryStatus { notNeeded, recovered, unsafe }

class WindowsCmakeCacheRecoveryResult {
  const WindowsCmakeCacheRecoveryResult(this.status, this.detail);

  final WindowsCmakeCacheRecoveryStatus status;
  final String detail;
}

class WindowsCmakeBuildRecoveryResult {
  const WindowsCmakeBuildRecoveryResult({
    required this.result,
    required this.recovery,
    required this.retried,
  });

  final CmakeBuildCommandResult result;
  final WindowsCmakeCacheRecoveryResult recovery;
  final bool retried;
}

/// Repairs only the verified Windows CMake generator cache after its exact
/// generator-mismatch error, then permits exactly one caller-provided retry.
class WindowsCmakeGeneratorCacheRecovery {
  static const _generatorMismatch = 'does not match the generator used previously';
  static const _cacheMarker = 'cmakecache.txt';

  static bool isExactGeneratorMismatch(Iterable<String> output) {
    final text = output.join('\n').toLowerCase();
    return text.contains(_generatorMismatch) && text.contains(_cacheMarker);
  }

  static Future<WindowsCmakeBuildRecoveryResult> runWithSingleRecovery({
    required String workspace,
    required Future<CmakeBuildCommandResult> Function() runBuild,
  }) async {
    final first = await runBuild();
    if (first.succeeded) {
      return WindowsCmakeBuildRecoveryResult(
        result: first,
        recovery: const WindowsCmakeCacheRecoveryResult(
          WindowsCmakeCacheRecoveryStatus.notNeeded,
          'Windows build uspel pri prvom pokuse.',
        ),
        retried: false,
      );
    }

    final recovery = await recoverIfExactGeneratorMismatch(
      workspace: workspace,
      output: first.output,
    );
    if (recovery.status != WindowsCmakeCacheRecoveryStatus.recovered) {
      return WindowsCmakeBuildRecoveryResult(
        result: first,
        recovery: recovery,
        retried: false,
      );
    }

    final retry = await runBuild();
    return WindowsCmakeBuildRecoveryResult(
      result: CmakeBuildCommandResult(
        retry.exitCode,
        <String>[
          ...first.output,
          'FIX394: ${recovery.detail}',
          'FIX394: opakujem Windows Release build presne raz.',
          ...retry.output,
        ],
      ),
      recovery: recovery,
      retried: true,
    );
  }

  static Future<WindowsCmakeCacheRecoveryResult> recoverIfExactGeneratorMismatch({
    required String workspace,
    required Iterable<String> output,
  }) async {
    if (!isExactGeneratorMismatch(output)) {
      return const WindowsCmakeCacheRecoveryResult(
        WindowsCmakeCacheRecoveryStatus.notNeeded,
        'Výstup neobsahuje presný konflikt CMake generátora.',
      );
    }

    final root = path.normalize(path.absolute(workspace));
    final binary = path.join(root, 'build', 'windows', 'x64');
    final cache = File(path.join(binary, 'CMakeCache.txt'));
    final files = Directory(path.join(binary, 'CMakeFiles'));
    final expectedHome = path.normalize(path.join(root, 'windows'));

    if (await FileSystemEntity.type(cache.path, followLinks: false) !=
            FileSystemEntityType.file ||
        await FileSystemEntity.type(files.path, followLinks: false) !=
            FileSystemEntityType.directory) {
      return const WindowsCmakeCacheRecoveryResult(
        WindowsCmakeCacheRecoveryStatus.unsafe,
        'FIX394 preskočené: potvrdená cache alebo CMakeFiles v build/windows/x64 chýba.',
      );
    }

    String content;
    try {
      content = await cache.readAsString();
    } on FileSystemException catch (error) {
      return WindowsCmakeCacheRecoveryResult(
        WindowsCmakeCacheRecoveryStatus.unsafe,
        'FIX394 preskočené: CMakeCache.txt sa nedá bezpečne čítať: $error',
      );
    }
    final match = RegExp(r'^CMAKE_HOME_DIRECTORY(?::[^=]+)?=(.+)$', multiLine: true)
        .firstMatch(content);
    final configuredHome = match?.group(1)?.trim();
    if (configuredHome == null ||
        !path.equals(path.normalize(path.absolute(configuredHome)), expectedHome)) {
      return const WindowsCmakeCacheRecoveryResult(
        WindowsCmakeCacheRecoveryStatus.unsafe,
        'FIX394 preskočené: CMAKE_HOME_DIRECTORY nepatrí aktuálnemu workspace.',
      );
    }

    try {
      await cache.delete();
      await files.delete(recursive: true);
      return const WindowsCmakeCacheRecoveryResult(
        WindowsCmakeCacheRecoveryStatus.recovered,
        'Bezpečne odstránené iba build/windows/x64/CMakeCache.txt a CMakeFiles.',
      );
    } on FileSystemException catch (error) {
      return WindowsCmakeCacheRecoveryResult(
        WindowsCmakeCacheRecoveryStatus.unsafe,
        'FIX394 preskočené: potvrdenú cache nebolo možné odstrániť: $error',
      );
    }
  }
}
