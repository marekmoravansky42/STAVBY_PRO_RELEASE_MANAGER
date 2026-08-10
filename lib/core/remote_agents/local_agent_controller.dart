import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'agent_api.dart';

class LocalAgentController {
  Process? _process;
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;
  final List<String> _recentOutput = <String>[];
  bool _stopRequested = false;

  List<String> get recentOutput => List<String>.unmodifiable(_recentOutput);

  Process? get process => _process;
  bool get isRunning => _process != null;
  bool get ownsProcess => _process != null;

  Future<Directory> findAgentDirectory({String? projectRoot}) async {
    final candidates = <Directory>[];
    final explicitRoot = projectRoot?.trim();
    if (explicitRoot != null && explicitRoot.isNotEmpty) {
      candidates.add(Directory(
        '${Directory(explicitRoot).absolute.path}${Platform.pathSeparator}tools${Platform.pathSeparator}release_agent',
      ));
    }

    void addWithParents(Directory start) {
      var current = start.absolute;
      for (var i = 0; i < 8; i++) {
        candidates.add(Directory(
          '${current.path}${Platform.pathSeparator}tools${Platform.pathSeparator}release_agent',
        ));
        final parent = current.parent;
        if (parent.path == current.path) break;
        current = parent;
      }
    }

    addWithParents(Directory.current);
    addWithParents(File(Platform.resolvedExecutable).parent);

    for (final directory in candidates) {
      if (await File(
        '${directory.path}${Platform.pathSeparator}pubspec.yaml',
      ).exists()) {
        return directory;
      }
    }

    throw FileSystemException(
      'Priečinok tools/release_agent sa nepodarilo nájsť. '
      'Očakávané umiestnenie: <aktuálny workspace>/tools/release_agent.',
    );
  }

  Future<void> start({
    int port = AgentApi.defaultPort,
    String? projectRoot,
    void Function(String line)? onOutput,
    void Function(int exitCode)? onExit,
  }) async {
    if (_process != null) return;
    _stopRequested = false;
    _recentOutput.clear();

    final directory = await findAgentDirectory(projectRoot: projectRoot);
    final process = await Process.start(
      'dart',
      <String>['run', 'bin/release_agent.dart', '$port', '--local'],
      workingDirectory: directory.path,
      runInShell: true,
    );
    _process = process;

    _stdoutSubscription = process.stdout
        .transform(const SystemEncoding().decoder)
        .transform(const LineSplitter())
        .listen((line) {
      _rememberOutput(line);
      onOutput?.call(line);
    });
    _stderrSubscription = process.stderr
        .transform(const SystemEncoding().decoder)
        .transform(const LineSplitter())
        .listen((line) {
      _rememberOutput(line);
      onOutput?.call(line);
    });

    unawaited(process.exitCode.then((exitCode) async {
      await _stdoutSubscription?.cancel();
      await _stderrSubscription?.cancel();
      _stdoutSubscription = null;
      _stderrSubscription = null;
      _process = null;
      if (!_stopRequested) {
        onExit?.call(exitCode);
      }
    }));
  }

  void _rememberOutput(String line) {
    final value = line.trim();
    if (value.isEmpty) return;
    _recentOutput.add(value);
    if (_recentOutput.length > 30) {
      _recentOutput.removeAt(0);
    }
  }

  Future<void> stop() async {
    final process = _process;
    if (process == null) return;
    _stopRequested = true;

    process.kill(ProcessSignal.sigterm);
    try {
      await process.exitCode.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
    }

    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();
    _stdoutSubscription = null;
    _stderrSubscription = null;
    _process = null;
  }
}
