import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/release_pipeline/pipeline_executor.dart';
import '../../core/release_pipeline/execution_history_entry.dart';
import '../../core/release_pipeline/execution_history_service.dart';
import '../../core/release_pipeline/pipeline_template.dart';
import '../../core/project_workspace/project_platform.dart';
import '../../core/project_workspace/project_workspace.dart';
import '../../core/project_workspace/preflight_validator.dart';

/// Executes a selected declarative pipeline in a project workspace.
///
/// The controller knows only stable action identifiers. Concrete commands are
/// registered in [_createActions], so future plugins can provide more actions
/// without changing the execution model.
class ReleasePipelineExecutionController extends ChangeNotifier {
  ReleasePipelineExecutionController({this.onLog});

  final void Function(String message)? onLog;

  bool _running = false;
  PipelineExecutionReport? _report;
  PipelineExecutionSummary? _summary;
  final Map<String, PipelineStepExecution> _stepStates =
      <String, PipelineStepExecution>{};
  String? _error;
  String? _activeStepId;
  Timer? _elapsedTicker;
  DateTime? _runStartedAt;
  Process? _activeProcess;
  bool _cancelRequested = false;
  List<ExecutionHistoryEntry> _history = const <ExecutionHistoryEntry>[];
  final ExecutionHistoryService _historyService = const ExecutionHistoryService();

  bool get running => _running;
  bool get cancelRequested => _cancelRequested;
  PipelineExecutionReport? get report => _report;
  PipelineExecutionSummary? get summary => _summary;
  String? get error => _error;
  List<ExecutionHistoryEntry> get history => List<ExecutionHistoryEntry>.unmodifiable(_history);
  Map<String, PipelineStepExecution> get stepStates =>
      Map<String, PipelineStepExecution>.unmodifiable(_stepStates);

  PipelineStepExecution? stateFor(String stepId) => _stepStates[stepId];

  int get totalSteps => _stepStates.length;
  int get completedSteps =>
      _stepStates.values.where((state) => state.completed).length;
  double get progress => totalSteps == 0 ? 0 : completedSteps / totalSteps;
  Duration get elapsed {
    final report = _report;
    if (report != null) return report.finishedAt.difference(report.startedAt);
    final startedAt = _runStartedAt;
    return startedAt == null ? Duration.zero : DateTime.now().difference(startedAt);
  }

  int get progressPercent => (progress * 100).round();

  PipelineStepExecution? get activeStep {
    for (final state in _stepStates.values) {
      if (state.status == PipelineExecutionStatus.running) return state;
    }
    return null;
  }

  Future<bool> run({
    required PipelineTemplate template,
    required ProjectWorkspace workspace,
  }) async {
    if (_running) return false;
    final workingDirectory = workspace.rootPath;
    final directory = Directory(workingDirectory);
    if (!directory.existsSync()) {
      _error = 'Pracovný priečinok neexistuje: $workingDirectory';
      notifyListeners();
      return false;
    }

    _running = true;
    _cancelRequested = false;
    _runStartedAt = DateTime.now();
    _activeStepId = null;
    _report = null;
    _summary = null;
    _error = null;
    _stepStates
      ..clear()
      ..addEntries(template.steps.map((step) => MapEntry(
            step.id,
            PipelineStepExecution(
              step: step,
              status: step.enabled
                  ? PipelineExecutionStatus.waiting
                  : PipelineExecutionStatus.skipped,
              message: step.enabled ? '' : 'Krok je vypnutý.',
            ),
          )));
    _startElapsedTicker();
    notifyListeners();

    _writeLog('=== PIPELINE ${template.name} ===');
    _writeLog('Pracovný priečinok: $workingDirectory');

    try {
      final preflight = await const PreflightValidator().validate(workspace);
      for (final check in preflight.checks) {
        _writeLog('${check.passed ? '✔' : '✖'} ${check.name}: ${check.message}');
      }
      if (!preflight.passed) {
        throw StateError('Preflight validácia nebola úspešná.');
      }
      final executor = PipelineExecutor(
        actions: _createActions(workspace),
        shouldCancel: () => _cancelRequested,
        skipReason: (step) {
          for (final id in step.requiredPlatforms) {
            final platform = ProjectPlatformLabel.fromId(id);
            if (platform != null && !workspace.supports(platform)) {
              return 'Platforma ${platform.label} nie je v cieľovom projekte podporovaná.';
            }
          }
          return null;
        },
      );
      final result = await executor.run(
        template,
        onStepChanged: (state) {
          final previous = _stepStates[state.step.id];
          final mergedLog = state.log.isNotEmpty
              ? state.log
              : (previous?.log ?? const <String>[]);
          _stepStates[state.step.id] = state.copyWith(log: mergedLog);
          _activeStepId = state.status == PipelineExecutionStatus.running
              ? state.step.id
              : (_activeStepId == state.step.id ? null : _activeStepId);
          notifyListeners();
        },
      );
      _report = result;
      _summary = PipelineExecutionSummary(
        runId: '${result.startedAt.microsecondsSinceEpoch}',
        projectName: workspace.projectName,
        projectPath: workspace.rootPath,
        pipelineName: template.name,
        startedAt: result.startedAt,
        finishedAt: result.finishedAt,
        platformLabels: workspace.platforms.map((platform) => platform.label).toList()..sort(),
        steps: result.steps,
        pluginIds: result.steps
            .map((step) => step.pluginId)
            .whereType<String>()
            .toSet(),
      );
      try {
        _history = await _historyService.add(_summary!);
      } catch (historyError) {
        _writeLog(
          '⚠ Pipeline bola dokončená, ale históriu sa nepodarilo uložiť: '
          '$historyError',
        );
      }
      _writeLog(_cancelRequested
          ? '■ Pipeline bola zrušená používateľom.'
          : result.succeeded
              ? '✔ Pipeline bola úspešne dokončená.'
              : '✖ Pipeline skončila s chybou.');
      return result.succeeded;
    } catch (error) {
      _error = 'Pipeline sa nepodarilo spustiť: $error';
      _writeLog('✖ $_error');
      return false;
    } finally {
      _elapsedTicker?.cancel();
      _elapsedTicker = null;
      _activeStepId = null;
      _activeProcess = null;
      _running = false;
      notifyListeners();
    }
  }


  Future<void> loadHistory(ProjectWorkspace workspace) async {
    try {
      _history = await _historyService.load(workspace.rootPath);
    } catch (historyError) {
      _history = const <ExecutionHistoryEntry>[];
      _writeLog('⚠ Históriu behov sa nepodarilo načítať: $historyError');
    }
    notifyListeners();
  }

  Future<void> cancel() async {
    if (!_running || _cancelRequested) return;
    _cancelRequested = true;
    _writeLog('■ Zastavujem pipeline...');
    final process = _activeProcess;
    if (process != null) {
      process.kill(ProcessSignal.sigterm);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      process.kill(ProcessSignal.sigkill);
    }
    notifyListeners();
  }

  void clearResult() {
    if (_running) return;
    _report = null;
    _summary = null;
    _error = null;
    _runStartedAt = null;
    _activeStepId = null;
    _stepStates.clear();
    _cancelRequested = false;
    notifyListeners();
  }

  Map<String, PipelineAction> _createActions(ProjectWorkspace workspace) {
    return <String, PipelineAction>{
      'flutter_clean': (_) => _runCommand(
            executable: 'flutter',
            arguments: const <String>['clean'],
            workspace: workspace,
          ),
      'flutter_pub_get': (_) => _runCommand(
            executable: 'flutter',
            arguments: const <String>['pub', 'get'],
            workspace: workspace,
          ),
      'flutter_analyze': (_) => _runCommand(
            executable: 'flutter',
            arguments: const <String>['analyze'],
            workspace: workspace,
          ),
      'flutter_test': (_) => _runCommand(
            executable: 'flutter',
            arguments: const <String>['test'],
            workspace: workspace,
          ),
      'windows_build': (_) => _runCommand(
            executable: 'flutter',
            arguments: const <String>['build', 'windows', '--release'],
            workspace: workspace,
          ),
      'android_apk': (_) => _runCommand(
            executable: 'flutter',
            arguments: const <String>['build', 'apk', '--release'],
            workspace: workspace,
          ),
      'android_aab': (_) => _runCommand(
            executable: 'flutter',
            arguments: const <String>['build', 'appbundle', '--release'],
            workspace: workspace,
          ),
      'git_sync': (_) => _runCommand(
            executable: 'git',
            arguments: const <String>['status', '--short', '--branch'],
            workspace: workspace,
          ),
      'diagnostics_export': (_) async {
        const message =
            'Diagnostický krok nemá samostatný príkaz; výsledky sú dostupné v živom termináli.';
        _writeLog(message);
        return message;
      },
    };
  }

  Future<String?> _runCommand({
    required String executable,
    required List<String> arguments,
    required ProjectWorkspace workspace,
  }) async {
    final command = '$executable ${arguments.join(' ')}';
    _writeLog('▶ $command');

    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workspace.rootPath,
      runInShell: true,
    );
    _activeProcess = process;

    final output = <String>[];
    final stdoutDone = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      output.add(line);
      _writeLog(line);
    }).asFuture<void>();
    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      output.add(line);
      _writeLog(line);
    }).asFuture<void>();

    final exitCode = await process.exitCode;
    if (identical(_activeProcess, process)) _activeProcess = null;
    await Future.wait<void>(<Future<void>>[stdoutDone, stderrDone]);
    if (exitCode != 0) {
      throw ProcessException(
        executable,
        arguments,
        output.isEmpty
            ? 'Príkaz skončil s návratovým kódom $exitCode.'
            : output.takeLast(12).join('\n'),
        exitCode,
      );
    }
    final message = 'Hotovo: $command';
    _writeLog('✔ $message');
    return message;
  }

  void _startElapsedTicker() {
    _elapsedTicker?.cancel();
    _elapsedTicker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_running) notifyListeners();
    });
  }

  void _writeLog(String message) {
    final stepId = _activeStepId;
    if (stepId != null) {
      final current = _stepStates[stepId];
      if (current != null) {
        final nextLog = <String>[...current.log, message];
        _stepStates[stepId] = current.copyWith(log: nextLog);
        notifyListeners();
      }
    }
    onLog?.call(message);
  }

  @override
  void dispose() {
    _activeProcess?.kill(ProcessSignal.sigkill);
    _elapsedTicker?.cancel();
    super.dispose();
  }
}

extension<T> on List<T> {
  Iterable<T> takeLast(int count) {
    if (length <= count) return this;
    return skip(length - count);
  }
}
