import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

enum AndroidGradleCacheRecoveryStatus { recovered, notNeeded, blocked }

class AndroidGradleProcess {
  const AndroidGradleProcess({
    required this.id,
    required this.parentId,
    required this.name,
    required this.commandLine,
  });

  final int id;
  final int parentId;
  final String name;
  final String commandLine;

  factory AndroidGradleProcess.fromJson(Map<String, dynamic> json) {
    int number(String key) => (json[key] as num?)?.toInt() ?? 0;
    return AndroidGradleProcess(
      id: number('ProcessId'),
      parentId: number('ParentProcessId'),
      name: json['Name']?.toString() ?? '',
      commandLine: json['CommandLine']?.toString() ?? '',
    );
  }
}

class AndroidGradleCacheRecoveryResult {
  const AndroidGradleCacheRecoveryResult({
    required this.status,
    required this.detail,
    this.stoppedProcesses = const <AndroidGradleProcess>[],
  });

  final AndroidGradleCacheRecoveryStatus status;
  final String detail;
  final List<AndroidGradleProcess> stoppedProcesses;
}

/// Releases only the disposable Gradle cache used by an Android APK build.
/// Project data, Android sources and all other Gradle caches are out of scope.
class AndroidGradleCacheRecovery {
  static const _cacheDirectoryName = '.gradle-release';

  static String cacheDirectoryFor(String workspace) => path.join(
      path.normalize(path.absolute(workspace)), 'android', _cacheDirectoryName);

  static bool isSupportedBuildProcess(String name) {
    final normalized = name.trim().toLowerCase();
    return normalized == 'flutter' ||
        normalized == 'flutter.bat' ||
        normalized == 'dart' ||
        normalized == 'dart.exe' ||
        normalized == 'java' ||
        normalized == 'java.exe' ||
        normalized == 'javaw.exe' ||
        normalized == 'gradle' ||
        normalized == 'gradle.bat' ||
        normalized == 'gradlew' ||
        normalized == 'gradlew.bat';
  }

  /// Gradle can return exit code 1 on Windows after it has already written a
  /// release APK, solely because its own shutdown cannot release cache locks.
  /// This deliberately does not match ordinary Android build failures.
  static bool isExactCleanupLockFailure(Iterable<String> output) {
    final text = output.join('\n').toLowerCase();
    return text.contains('could not stop all services') &&
        text.contains('failed to release lock on') &&
        text.contains('gradle') &&
        (text.contains('buildoutputcleanup') ||
            text.contains('executionhistory'));
  }

  /// Returns an APK only when it was created by the current build and has a
  /// ZIP header. A prior APK can never turn a real failed build into success.
  static Future<File?> verifiedCurrentReleaseApk({
    required String workspace,
    required DateTime buildStartedAt,
  }) async {
    final file = File(path.join(
      path.normalize(path.absolute(workspace)),
      'build',
      'app',
      'outputs',
      'flutter-apk',
      'app-release.apk',
    ));
    if (!await file.exists()) return null;
    final stat = await file.stat();
    if (stat.size < 1024 ||
        stat.modified.isBefore(
          buildStartedAt.subtract(const Duration(seconds: 2)),
        )) {
      return null;
    }
    final header = await file.openRead(0, 4).fold<List<int>>(
      <int>[],
      (bytes, chunk) => <int>[...bytes, ...chunk],
    );
    if (header.length != 4 ||
        header[0] != 0x50 ||
        header[1] != 0x4b ||
        header[2] != 0x03 ||
        header[3] != 0x04) {
      return null;
    }
    return file;
  }

  /// Returns only build-process roots explicitly mentioning [workspace] and
  /// their Flutter/Dart/Java/Gradle descendants. Unrelated Java processes are
  /// intentionally excluded.
  static List<AndroidGradleProcess> projectBuildProcesses(
    Iterable<AndroidGradleProcess> processes,
    String workspace,
  ) {
    final normalizedWorkspace = path
        .normalize(path.absolute(workspace))
        .replaceAll('/', r'\\')
        .toLowerCase();
    final all = processes.where((process) => process.id > 0).toList();
    final children = <int, List<AndroidGradleProcess>>{};
    for (final process in all) {
      children
          .putIfAbsent(process.parentId, () => <AndroidGradleProcess>[])
          .add(process);
    }

    final roots = all.where((process) {
      final command = process.commandLine.replaceAll('/', r'\\').toLowerCase();
      return isSupportedBuildProcess(process.name) &&
          command.contains(normalizedWorkspace);
    });

    final selected = <int, AndroidGradleProcess>{};
    final visited = <int>{};
    void visit(AndroidGradleProcess process) {
      if (!visited.add(process.id)) return;
      if (isSupportedBuildProcess(process.name)) selected[process.id] = process;
      for (final child
          in children[process.id] ?? const <AndroidGradleProcess>[]) {
        visit(child);
      }
    }

    for (final root in roots) {
      visit(root);
    }
    return selected.values.toList(growable: false);
  }

  static Future<AndroidGradleCacheRecoveryResult> prepare({
    required String workspace,
    Future<List<AndroidGradleProcess>> Function()? listProcesses,
    Future<bool> Function(int processId)? stopProcess,
  }) async {
    if (!Platform.isWindows) {
      return const AndroidGradleCacheRecoveryResult(
        status: AndroidGradleCacheRecoveryStatus.notNeeded,
        detail: 'Android Gradle cache recovery je určená pre Windows.',
      );
    }

    final root = path.normalize(path.absolute(workspace));
    final cachePath = cacheDirectoryFor(root);
    if (!path.isWithin(root, cachePath) ||
        path.basename(cachePath) != _cacheDirectoryName) {
      return const AndroidGradleCacheRecoveryResult(
        status: AndroidGradleCacheRecoveryStatus.blocked,
        detail:
            'Ochrana cesty: cieľ Android Gradle cache nie je v aktuálnom workspace.',
      );
    }

    final processList = listProcesses ?? _listWindowsProcesses;
    final processStopper = stopProcess ?? _stopWindowsProcess;
    final selected = projectBuildProcesses(await processList(), root);
    final stopped = <AndroidGradleProcess>[];
    for (final process in selected.reversed) {
      if (await processStopper(process.id)) stopped.add(process);
    }

    final cache = Directory(cachePath);
    if (!await cache.exists()) {
      return AndroidGradleCacheRecoveryResult(
        status: AndroidGradleCacheRecoveryStatus.notNeeded,
        detail: stopped.isEmpty
            ? 'Android .gradle-release cache neexistuje; pokračujem buildom.'
            : 'Ukončené staré projektové build procesy (${_processLabel(stopped)}); Android .gradle-release cache neexistuje.',
        stoppedProcesses: stopped,
      );
    }

    try {
      await cache.delete(recursive: true);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (await cache.exists()) {
        final remaining = await cache.list(followLinks: false).toList();
        if (remaining.isNotEmpty) {
          return AndroidGradleCacheRecoveryResult(
            status: AndroidGradleCacheRecoveryStatus.blocked,
            detail:
                'Android Gradle cache zostala obsadená: $cachePath. Zostávajúci súbor alebo priečinok: ${remaining.first.path}.',
            stoppedProcesses: stopped,
          );
        }
      }
      return AndroidGradleCacheRecoveryResult(
        status: AndroidGradleCacheRecoveryStatus.recovered,
        detail:
            'Pripravené pre Android APK: odstránený iba $cachePath${stopped.isEmpty ? '' : '; ukončené projektové procesy: ${_processLabel(stopped)}'}.',
        stoppedProcesses: stopped,
      );
    } on FileSystemException catch (error) {
      final processDetail = selected.isEmpty
          ? 'Nenašiel sa projektový Flutter/Dart/Java/Gradle proces.'
          : 'Skontroluj proces: ${_processLabel(selected)}.';
      return AndroidGradleCacheRecoveryResult(
        status: AndroidGradleCacheRecoveryStatus.blocked,
        detail:
            'Android Gradle cache sa nedá odstrániť: $cachePath. $processDetail Súborový systém hlási: ${error.message}',
        stoppedProcesses: stopped,
      );
    }
  }

  static String _processLabel(Iterable<AndroidGradleProcess> processes) =>
      processes
          .map((process) => '${process.name} (PID ${process.id})')
          .join(', ');

  /// Windows command lines can contain raw control characters. PowerShell's
  /// JSON writer does not reliably escape all of them, so accept the process
  /// list only after replacing such transport-invalid characters. A malformed
  /// list simply means no process is selected; it must never terminate the UI.
  static List<AndroidGradleProcess> decodeWindowsProcessJson(String source) {
    final sanitized = source.replaceAll(RegExp(r'[\x00-\x1F]'), ' ');
    try {
      final decoded = jsonDecode(sanitized);
      final values = decoded is List ? decoded : <dynamic>[decoded];
      return values
          .whereType<Map>()
          .map((value) => AndroidGradleProcess.fromJson(
                value.map((key, item) => MapEntry(key.toString(), item)),
              ))
          .toList(growable: false);
    } on FormatException {
      return const <AndroidGradleProcess>[];
    }
  }

  static Future<List<AndroidGradleProcess>> _listWindowsProcesses() async {
    final result = await Process.run(
      'powershell.exe',
      <String>[
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        r'''$clean = { param($value) if ($null -eq $value) { '' } else { [regex]::Replace([string]$value, '[\x00-\x1F]', ' ') } }; Get-CimInstance Win32_Process | ForEach-Object { [pscustomobject]@{ ProcessId = $_.ProcessId; ParentProcessId = $_.ParentProcessId; Name = & $clean $_.Name; CommandLine = & $clean $_.CommandLine } } | ConvertTo-Json -Compress''',
      ],
      runInShell: false,
    );
    if (result.exitCode != 0 || result.stdout.toString().trim().isEmpty) {
      return const <AndroidGradleProcess>[];
    }
    return decodeWindowsProcessJson(result.stdout.toString());
  }

  static Future<bool> _stopWindowsProcess(int processId) async {
    final result = await Process.run(
      'taskkill.exe',
      <String>['/pid', '$processId', '/f'],
      runInShell: false,
    );
    return result.exitCode == 0;
  }
}
