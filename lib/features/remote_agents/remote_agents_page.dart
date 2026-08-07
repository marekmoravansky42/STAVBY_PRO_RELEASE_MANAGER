import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/remote_agents/agent_api.dart';
import '../../core/remote_agents/agent_pool.dart';
import '../../core/remote_agents/local_agent_controller.dart';
import '../../core/remote_agents/remote_agent.dart';
import '../../core/remote_agents/remote_agent_service.dart';
import '../../core/remote_agents/scheduler_service.dart';
import '../../shared/widgets/rm_section_card.dart';

class RemoteAgentsPage extends StatefulWidget {
  const RemoteAgentsPage({super.key});

  @override
  State<RemoteAgentsPage> createState() => _RemoteAgentsPageState();
}

class _RemoteAgentsPageState extends State<RemoteAgentsPage> {
  final _hostController = TextEditingController(text: '127.0.0.1');
  final _portController = TextEditingController(text: '${AgentApi.defaultPort}');
  late final TextEditingController _projectPathController;
  final RemoteAgentService _service = const RemoteAgentService();
  final AgentPool _agentPool = AgentPool();
  final SchedulerService _scheduler = const SchedulerService();
  final LocalAgentController _localAgent = LocalAgentController();
  Timer? _heartbeatTimer;
  Timer? _taskPollTimer;
  RemoteAgent? _agent;
  RemoteAgentTask? _task;
  final Set<String> _persistedTaskIds = <String>{};
  bool _busy = false;
  bool _startingLocalAgent = false;
  bool _startingTask = false;
  bool _pipelineRunning = false;
  bool _pipelineAnalyze = true;
  bool _pipelineTest = true;
  bool _pipelineWindowsBuild = true;
  DateTime? _pipelineStartedAt;
  DateTime? _pipelineFinishedAt;
  final List<_AgentPipelineStep> _pipelineSteps = <_AgentPipelineStep>[
    _AgentPipelineStep(
      type: 'analyze',
      label: 'Flutter Analyze',
      dependencies: const <String>[],
    ),
    _AgentPipelineStep(
      type: 'test',
      label: 'Flutter Test',
      dependencies: const <String>['analyze'],
    ),
    _AgentPipelineStep(
      type: 'windowsBuild',
      label: 'Windows Release Build',
      dependencies: const <String>['test'],
    ),
  ];
  String? _error;
  String _pingText = 'Ping ešte nebol spustený.';
  String _localAgentText = 'Local Agent nie je spustený.';
  bool _initialAgentBootstrapStarted = false;

  @override
  void initState() {
    super.initState();
    _projectPathController = TextEditingController();
    _projectPathController.addListener(_onProjectPathChanged);
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_busy) unawaited(_refreshAgentPool());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapLocalAgent());
    });
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _taskPollTimer?.cancel();
    unawaited(_localAgent.stop());
    _hostController.dispose();
    _portController.dispose();
    _projectPathController.removeListener(_onProjectPathChanged);
    _projectPathController.dispose();
    super.dispose();
  }


  void _onProjectPathChanged() {
    if (mounted) setState(() {});
  }

  bool get _hasValidFlutterProject {
    final value = _projectPathController.text.trim();
    if (value.isEmpty) return false;
    return File('$value${Platform.pathSeparator}pubspec.yaml').existsSync();
  }

  Future<String?> _findFlutterProjectRoot(String selectedPath) async {
    final selected = Directory(selectedPath);
    if (await File('${selected.path}${Platform.pathSeparator}pubspec.yaml').exists()) {
      return selected.path;
    }

    // ZIP balíky Release Managera často obsahujú koreň Bxxx/. Prehľadáme
    // najviac dve úrovne, aby výber nadradeného priečinka zostal pohodlný,
    // ale neprechádzal celý disk.
    var current = <Directory>[selected];
    for (var depth = 0; depth < 2; depth++) {
      final next = <Directory>[];
      for (final directory in current) {
        try {
          await for (final entity in directory.list(followLinks: false)) {
            if (entity is! Directory) continue;
            if (await File('${entity.path}${Platform.pathSeparator}pubspec.yaml').exists()) {
              return entity.path;
            }
            next.add(entity);
          }
        } catch (_) {
          // Neprístupný podadresár iba preskočíme.
        }
      }
      current = next;
    }
    return null;
  }

  Future<void> _pickFlutterProject() async {
    final selectedPath = await FilePicker.getDirectoryPath(
      dialogTitle: 'Vyber koreň Flutter projektu',
    );
    if (selectedPath == null || !mounted) return;

    final projectRoot = await _findFlutterProjectRoot(selectedPath);
    if (!mounted) return;
    if (projectRoot == null) {
      setState(() {
        _projectPathController.text = '';
        _error = 'Vo vybranom priečinku ani v jeho prvých dvoch úrovniach '
            'sa nenašiel pubspec.yaml.';
      });
      return;
    }

    setState(() {
      _projectPathController.text = projectRoot;
      _error = null;
      _task = null;
    });
  }

  int get _port => int.tryParse(_portController.text.trim()) ?? AgentApi.defaultPort;


  String _friendlyAgentError(Object error) {
    if (error is SocketException) {
      return 'Agent nie je pripojený. Spusti Local Agent alebo zadaj adresu '
          'vzdialeného agenta a klikni na PRIPOJIŤ / OBNOVIŤ.';
    }
    final text = error.toString();
    if (text.contains('Connection refused') ||
        text.contains('refused the network connection') ||
        text.contains('errno = 1225')) {
      return 'Agent nie je pripojený. Spusti Local Agent alebo sa pripoj '
          'k vzdialenému agentovi.';
    }
    return 'Agent nie je dostupný: $text';
  }

  void _upsertAgent(RemoteAgent agent, {bool makeCurrent = true}) {
    _agentPool.upsert(agent);
    if (makeCurrent) _agent = agent;
    for (final step in _pipelineSteps) {
      step.selectedAgentId ??= agent.id;
    }
  }

  Future<void> _refreshAgentPool() async {
    final snapshot = _agentPool.agents;
    if (snapshot.isEmpty) return;
    for (final current in snapshot) {
      try {
        final refreshed = await _service.readStatus(current.host, port: current.port);
        if (!mounted) return;
        setState(() {
          _agentPool.upsert(refreshed);
          if (_agent?.id == refreshed.id) _agent = refreshed;
        });
      } catch (_) {
        // Záznam ponecháme v poole; po 12 sekundách sa zobrazí ako OFFLINE.
      }
    }
  }

  RemoteAgent? get _firstOnlineAgent {
    for (final item in _agentPool.agents) {
      if (item.isOnline) return item;
    }
    return null;
  }

  RemoteAgent? _agentForStep(_AgentPipelineStep step) {
    if (step.selectedAgentId == _AgentPipelineStep.autoAgentId) {
      return _scheduler.selectBest(_agentPool.agents, step.type);
    }
    return _agentPool.getById(step.selectedAgentId) ?? _agent;
  }

  Future<void> _bootstrapLocalAgent() async {
    if (_initialAgentBootstrapStarted || !mounted) return;
    _initialAgentBootstrapStarted = true;
    try {
      final existing = await _service.readStatus('127.0.0.1', port: _port);
      if (!mounted) return;
      if (existing.supportsAnalyze &&
          existing.supportsTest &&
          existing.supportsWindowsBuild) {
        setState(() {
          _upsertAgent(existing);
          _error = null;
          _localAgentText =
              'Local Agent už beží na localhost:$_port; spojenie bolo automaticky obnovené.';
        });
        return;
      }
    } catch (_) {
      // Agent ešte nebeží; spustíme ho automaticky.
    }
    await _startLocalAgent();
  }

  Future<void> _startPipelineWithAgentCheck() async {
    if (_firstOnlineAgent != null) {
      await _startAgentPipeline();
      return;
    }
    final start = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agent nie je pripojený'),
        content: const Text(
          'Pre spustenie pipeline musí byť dostupný Local Agent alebo '
          'vzdialený agent. Chceš teraz spustiť Local Agent?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ZRUŠIŤ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('SPUSTIŤ LOCAL AGENT'),
          ),
        ],
      ),
    );
    if (start != true || !mounted) return;
    await _startLocalAgent();
    if (_agent != null && mounted) {
      await _startAgentPipeline();
    }
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _busy = true;
        _error = null;
      });
    }
    try {
      final agent = await _service.readStatus(
        _hostController.text.trim(),
        port: _port,
      );
      if (!mounted) return;
      setState(() {
        _upsertAgent(agent);
        _error = null;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (_agent != null) _agentPool.remove(_agent!.id);
        _agent = _firstOnlineAgent;
        _error = _friendlyAgentError(error);
        _busy = false;
      });
    }
  }

  Future<void> _ping() async {
    setState(() {
      _busy = true;
      _pingText = 'Testujem spojenie...';
    });
    final result = await _service.ping(
      _hostController.text.trim(),
      port: _port,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _pingText = result.ok
          ? 'OK • ${result.latencyMs} ms'
          : 'CHYBA • ${result.message}';
    });
  }

  Future<void> _startLocalAgent() async {
    if (_startingLocalAgent || _localAgent.isRunning) return;
    setState(() {
      _startingLocalAgent = true;
      _busy = true;
      _error = null;
      _localAgentText = 'Spúšťam Local Agent...';
      _hostController.text = '127.0.0.1';
    });

    try {
      // Po páde alebo reštarte Release Managera môže na porte stále bežať
      // predchádzajúci Local Agent. V takom prípade ho iba prevezmeme namiesto
      // spúšťania druhého procesu, ktorý by zlyhal na obsadenom porte.
      try {
        final existing = await _service.readStatus('127.0.0.1', port: _port);
        if (!existing.supportsAnalyze ||
            !existing.supportsTest ||
            !existing.supportsWindowsBuild) {
          throw StateError(
            'Na porte $_port beží starší nekompatibilný agent '
            '(protokol ${existing.protocolVersion}). Použi port ${AgentApi.defaultPort}.',
          );
        }
        if (!mounted) return;
        setState(() {
          _upsertAgent(existing);
          _pingText = 'Pripojený existujúci Local Agent.';
          _localAgentText =
              'Local Agent už beží na localhost:$_port; spojenie bolo prevzaté.';
        });
        return;
      } catch (_) {
        // Port nie je obsadený kompatibilným agentom; spustíme nový proces.
      }

      await _localAgent.start(
        port: _port,
        onOutput: (line) {
          if (!mounted || line.trim().isEmpty) return;
          setState(() => _localAgentText = line.trim());
        },
        onExit: (exitCode) async {
          if (!mounted) return;

          // Ak už na porte odpovedá iný kompatibilný agent, nový proces iba
          // zlyhal na obsadenom porte. Spojenie preto zachováme a prevezmeme ho.
          try {
            final existing = await _service.readStatus('127.0.0.1', port: _port);
            if (!existing.supportsAnalyze ||
            !existing.supportsTest ||
            !existing.supportsWindowsBuild) {
              throw StateError('Na porte beží nekompatibilný agent.');
            }
            if (!mounted) return;
            setState(() {
              _upsertAgent(existing);
              _localAgentText =
                  'Na porte už bežal Local Agent; spojenie bolo prevzaté.';
              _error = null;
            });
            return;
          } catch (_) {}

          final output = _localAgent.recentOutput;
          final detail = output.isEmpty
              ? 'Agent neposkytol ďalší diagnostický výstup.'
              : output.skip(output.length > 12 ? output.length - 12 : 0).join('\n');
          setState(() {
            _localAgentText = exitCode == 0
                ? 'Local Agent bol ukončený.'
                : 'Local Agent sa neočakávane ukončil (kód $exitCode).';
            _error = exitCode == 0
                ? null
                : 'Diagnostika Local Agenta:\n$detail';
            _agent = null;
            _taskPollTimer?.cancel();
          });
        },
      );

      RemoteAgent? connectedAgent;
      Object? lastError;
      for (var attempt = 0; attempt < 12; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        try {
          connectedAgent = await _service.readStatus('127.0.0.1', port: _port);
          break;
        } catch (error) {
          lastError = error;
        }
      }
      final readyAgent = connectedAgent;
      if (readyAgent == null) {
        throw StateError('Local Agent sa nespustil včas: $lastError');
      }
      if (!mounted) return;
      setState(() {
        _upsertAgent(readyAgent);
        _pingText = 'Pripravený na test spojenia.';
        _localAgentText = 'Local Agent beží na localhost:$_port.';
      });
    } catch (error) {
      await _localAgent.stop();
      if (!mounted) return;
      setState(() {
        _error = 'Local Agent sa nepodarilo spustiť: $error';
        _localAgentText = 'Local Agent nie je spustený.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _startingLocalAgent = false;
          _busy = false;
        });
      }
    }
  }

  Future<void> _stopLocalAgent() async {
    if (!_localAgent.isRunning) return;
    setState(() {
      _busy = true;
      _localAgentText = 'Zastavujem Local Agent...';
    });
    _taskPollTimer?.cancel();
    await _localAgent.stop();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (_agent != null) _agentPool.remove(_agent!.id);
      _agent = _firstOnlineAgent;
      _task = null;
      _startingTask = false;
      _localAgentText = 'Local Agent bol zastavený.';
      _pingText = 'Ping ešte nebol spustený.';
      _error = null;
    });
  }

  Future<void> _startAnalyze() => _startRemoteTask('analyze');

  Future<void> _startTest() => _startRemoteTask('test');

  Future<void> _startWindowsBuild() => _startRemoteTask('windowsBuild');

  Future<void> _startRemoteTask(String taskType) async {
    final agent = _agent;
    final path = _projectPathController.text.trim();
    if (agent == null || _startingTask || (_task != null && !_task!.isFinished)) return;
    final supported = switch (taskType) {
      'test' => agent.supportsTest,
      'windowsBuild' => agent.supportsWindowsBuild,
      _ => agent.supportsAnalyze,
    };
    if (!supported) {
      final command = switch (taskType) {
        'test' => 'flutter test',
        'windowsBuild' => 'flutter build windows --release',
        _ => 'flutter analyze',
      };
      setState(() => _error =
          'Pripojený agent nepodporuje $command (protokol ${agent.protocolVersion}).');
      return;
    }
    if (path.isEmpty) {
      setState(() => _error = 'Vyber Flutter projekt.');
      return;
    }
    if (!File('$path${Platform.pathSeparator}pubspec.yaml').existsSync()) {
      setState(() => _error =
          'Vybraný priečinok nie je koreň Flutter projektu – chýba pubspec.yaml.');
      return;
    }

    setState(() {
      _startingTask = true;
      _error = null;
      _task = null;
    });

    try {
      final task = switch (taskType) {
        'test' => await _service.startTest(
            agent.host,
            port: agent.port,
            workingDirectory: path,
          ),
        'windowsBuild' => await _service.startWindowsBuild(
            agent.host,
            port: agent.port,
            workingDirectory: path,
          ),
        _ => await _service.startAnalyze(
            agent.host,
            port: agent.port,
            workingDirectory: path,
          ),
      };
      if (!mounted) return;
      setState(() {
        _task = task;
        _startingTask = false;
      });
      _taskPollTimer?.cancel();
      _taskPollTimer = Timer.periodic(
        const Duration(milliseconds: 700),
        (_) => unawaited(_pollTask()),
      );
      await _pollTask();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _startingTask = false;
        _error = 'Úlohu sa nepodarilo spustiť: $error';
      });
    }
  }

  List<_AgentPipelineStep> get _selectedPipelineSteps => _pipelineSteps.where((step) {
        return switch (step.type) {
          'analyze' => _pipelineAnalyze,
          'test' => _pipelineTest,
          'windowsBuild' => _pipelineWindowsBuild,
          _ => false,
        };
      }).toList(growable: false);

  Future<RemoteAgentTask> _submitPipelineTask(
    RemoteAgent agent,
    String type,
    String path,
  ) {
    return switch (type) {
      'test' => _service.startTest(
          agent.host,
          port: agent.port,
          workingDirectory: path,
        ),
      'windowsBuild' => _service.startWindowsBuild(
          agent.host,
          port: agent.port,
          workingDirectory: path,
        ),
      _ => _service.startAnalyze(
          agent.host,
          port: agent.port,
          workingDirectory: path,
        ),
    };
  }

  Future<RemoteAgentTask> _waitForPipelineTask(
    RemoteAgent agent,
    RemoteAgentTask initial,
  ) async {
    var current = initial;
    while (!current.isFinished) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      current = await _service.readTask(
        agent.host,
        current.id,
        port: agent.port,
      );
      if (!mounted) return current;
      setState(() => _task = current);
    }
    return current;
  }

  bool _isPipelineStepSuccessful(_AgentPipelineStep step) {
    return step.status == 'success' || step.status == 'warnings';
  }

  bool _dependenciesFinished(
    _AgentPipelineStep step,
    Map<String, _AgentPipelineStep> selectedByType,
  ) {
    for (final dependencyType in step.dependencies) {
      final dependency = selectedByType[dependencyType];
      if (dependency == null) continue;
      if (!_isPipelineStepSuccessful(dependency)) return false;
    }
    return true;
  }

  bool _hasFailedDependency(
    _AgentPipelineStep step,
    Map<String, _AgentPipelineStep> selectedByType,
  ) {
    for (final dependencyType in step.dependencies) {
      final dependency = selectedByType[dependencyType];
      if (dependency == null) continue;
      if (dependency.status == 'failed' || dependency.status == 'skipped') {
        return true;
      }
    }
    return false;
  }

  RemoteAgent? _resolveAgentForParallelStep(
    _AgentPipelineStep step,
    Set<String> reservedAgentIds,
  ) {
    if (step.selectedAgentId != _AgentPipelineStep.autoAgentId) {
      final selected = _agentPool.getById(step.selectedAgentId) ?? _agent;
      if (selected == null || reservedAgentIds.contains(selected.id)) return null;
      return _scheduler.validate(selected, step.type).isValid ? selected : null;
    }

    final candidates = _agentPool.agents.where(
      (candidate) => !reservedAgentIds.contains(candidate.id),
    );
    return _scheduler.selectBest(candidates, step.type);
  }

  Future<void> _executePipelineStep(
    _AgentPipelineStep step,
    RemoteAgent agent,
    String path,
  ) async {
    if (!mounted) return;
    setState(() {
      step
        ..status = 'running'
        ..resolvedAgentName = agent.name;
      _task = null;
    });

    final initial = await _submitPipelineTask(agent, step.type, path);
    if (!mounted) return;
    setState(() {
      step.task = initial;
      _task = initial;
    });

    final result = await _waitForPipelineTask(agent, initial);
    await _appendAgentTaskHistory(result);
    if (!mounted) return;
    setState(() {
      step
        ..task = result
        ..status = result.effectiveStatus;
      _task = result;
    });
  }

  Future<void> _startAgentPipeline() async {
    final path = _projectPathController.text.trim();
    final selected = _selectedPipelineSteps;
    if (_firstOnlineAgent == null || _pipelineRunning || _startingTask) return;
    if (!_hasValidFlutterProject) {
      setState(() => _error = 'Najprv vyber platný Flutter projekt.');
      return;
    }
    if (selected.isEmpty) {
      setState(() => _error = 'Vyber aspoň jeden krok pipeline.');
      return;
    }

    for (final step in selected) {
      final validation = _scheduler.validate(_agentForStep(step), step.type);
      if (!validation.isValid && step.selectedAgentId != _AgentPipelineStep.autoAgentId) {
        setState(() => _error = '${step.label}: ${validation.message}');
        return;
      }
      if (step.selectedAgentId == _AgentPipelineStep.autoAgentId &&
          _scheduler.selectBest(_agentPool.agents, step.type) == null) {
        setState(() => _error = '${step.label}: nie je dostupný kompatibilný agent.');
        return;
      }
    }

    _taskPollTimer?.cancel();
    setState(() {
      _pipelineRunning = true;
      _pipelineStartedAt = DateTime.now();
      _pipelineFinishedAt = null;
      _error = null;
      _task = null;
      for (final step in _pipelineSteps) {
        step
          ..status = selected.contains(step) ? 'waiting' : 'disabled'
          ..task = null
          ..resolvedAgentName = null;
      }
    });

    final selectedByType = <String, _AgentPipelineStep>{
      for (final step in selected) step.type: step,
    };

    try {
      while (selected.any((step) => step.status == 'waiting' || step.status == 'running')) {
        if (!mounted) return;

        for (final step in selected.where((item) => item.status == 'waiting')) {
          if (_hasFailedDependency(step, selectedByType)) {
            step.status = 'skipped';
          }
        }

        final ready = selected.where((step) {
          return step.status == 'waiting' &&
              _dependenciesFinished(step, selectedByType);
        }).toList(growable: false);

        if (ready.isEmpty) {
          if (selected.any((step) => step.status == 'running')) {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            continue;
          }
          final blocked = selected.where((step) => step.status == 'waiting').toList();
          for (final step in blocked) {
            step.status = 'skipped';
          }
          if (mounted) {
            setState(() => _error =
                'Pipeline obsahuje nesplniteľné alebo cyklické závislosti.');
          }
          break;
        }

        final reservedAgentIds = <String>{};
        final wave = <({ _AgentPipelineStep step, RemoteAgent agent })>[];
        for (final step in ready) {
          final agent = _resolveAgentForParallelStep(step, reservedAgentIds);
          if (agent == null) continue;
          reservedAgentIds.add(agent.id);
          wave.add((step: step, agent: agent));
        }

        if (wave.isEmpty) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          await _refreshAgentPool();
          continue;
        }

        await Future.wait<void>(
          wave.map((entry) => _executePipelineStep(entry.step, entry.agent, path)),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Pipeline zlyhala: $error');
    } finally {
      if (mounted) {
        setState(() {
          _pipelineRunning = false;
              _pipelineFinishedAt = DateTime.now();
        });
        await _refresh(silent: true);
      }
    }
  }

  Future<void> _copyTaskLog() async {
    final task = _task;
    if (task == null) return;
    final text = task.log.join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log bol skopírovaný do schránky.')),
    );
  }

  Future<void> _saveTaskLog() async {
    final task = _task;
    if (task == null) return;
    final suggestedName = 'remote_${task.command.replaceAll(' ', '_')}_${task.id}.log';
    final outputPath = await FilePicker.saveFile(
      dialogTitle: 'Uložiť log vzdialenej úlohy',
      fileName: suggestedName,
      type: FileType.custom,
      allowedExtensions: const <String>['log', 'txt'],
    );
    if (outputPath == null) return;
    await File(outputPath).writeAsString(task.log.join('\n'), flush: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Log bol uložený: $outputPath')),
    );
  }

  Future<void> _appendAgentTaskHistory(RemoteAgentTask task) async {
    if (!_persistedTaskIds.add(task.id)) return;
    final projectPath = _projectPathController.text.trim();
    if (projectPath.isEmpty) return;
    try {
      final directory = Directory(
        '$projectPath${Platform.pathSeparator}.release_manager',
      );
      await directory.create(recursive: true);
      final file = File(
        '${directory.path}${Platform.pathSeparator}agent_task_history.json',
      );
      List<dynamic> history = <dynamic>[];
      if (await file.exists()) {
        try {
          final decoded = jsonDecode(await file.readAsString());
          if (decoded is List<dynamic>) history = decoded;
        } catch (_) {
          // Poškodená história nesmie ovplyvniť výsledok úlohy.
        }
      }
      history.insert(0, <String, dynamic>{
        'id': task.id,
        'command': task.command,
        'workingDirectory': task.workingDirectory,
        'status': task.effectiveStatus,
        'rawStatus': task.status,
        'analyzeErrors': task.analyzeErrorCount,
        'analyzeWarnings': task.analyzeWarningCount,
        'analyzeInfos': task.analyzeInfoCount,
        'exitCode': task.exitCode,
        'error': task.error,
        'startedAt': task.startedAt?.toIso8601String(),
        'finishedAt': task.finishedAt?.toIso8601String(),
        'log': task.log,
      });
      if (history.length > 100) history = history.take(100).toList();
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
        const JsonEncoder.withIndent('  ').convert(history),
        flush: true,
      );
      if (await file.exists()) await file.delete();
      await temporary.rename(file.path);
    } catch (error) {
      _persistedTaskIds.remove(task.id);
      if (!mounted) return;
      setState(() => _error = 'Úloha skončila, ale históriu sa nepodarilo uložiť: $error');
    }
  }

  Future<void> _pollTask() async {
    final agent = _agent;
    final task = _task;
    if (agent == null || task == null) return;
    try {
      final refreshed = await _service.readTask(
        agent.host,
        task.id,
        port: agent.port,
      );
      if (!mounted) return;
      setState(() => _task = refreshed);
      if (refreshed.isFinished) {
        _taskPollTimer?.cancel();
        await _appendAgentTaskHistory(refreshed);
        await _refresh(silent: true);
      }
    } catch (error) {
      _taskPollTimer?.cancel();
      if (!mounted) return;
      setState(() => _error = 'Nepodarilo sa načítať stav úlohy: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final agent = _agent;
    final localRunning = _localAgent.isRunning;
    final taskRunning = _pipelineRunning || _startingTask || (_task != null && !_task!.isFinished);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RMSectionCard(
            title: 'Local Agent Mode',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Spusti Release Agent na tomto počítači a otestuj registráciu, '
                  'heartbeat, ping a vzdialené príkazy bez druhého zariadenia.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _busy || localRunning ? null : _startLocalAgent,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        _startingLocalAgent ? 'SPÚŠŤAM...' : 'SPUSTIŤ LOCAL AGENT',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy || !localRunning || taskRunning ? null : _stopLocalAgent,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('ZASTAVIŤ LOCAL AGENT'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _localAgentText,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: localRunning
                        ? Colors.green
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          RMSectionCard(
            title: 'Remote Build Agents',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Manuálne pripojenie zostáva dostupné pre neskorší test na druhom počítači.',
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _hostController,
                        decoration: const InputDecoration(
                          labelText: 'IP adresa alebo názov počítača',
                          prefixIcon: Icon(Icons.dns_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 130,
                      child: TextField(
                        controller: _portController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Port'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _busy ? null : _refresh,
                      icon: const Icon(Icons.link_rounded),
                      label: const Text('PRIDAŤ / OBNOVIŤ AGENTA'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _ping,
                      icon: const Icon(Icons.network_ping_rounded),
                      label: const Text('PING AGENT'),
                    ),
                  ],
                ),
                if (_busy) ...<Widget>[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          RMSectionCard(
            title: 'Remote Command Execution v1',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Vzdialené príkazy: flutter analyze, flutter test a Windows release build. Pri Local Agentovi '
                  'zadaj cestu k ľubovoľnému Flutter projektu na tomto počítači.',
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _projectPathController,
                        enabled: !taskRunning,
                        decoration: InputDecoration(
                          labelText: 'Cesta k cieľovému Flutter projektu',
                          prefixIcon: const Icon(Icons.folder_open_rounded),
                          helperText: _projectPathController.text.trim().isEmpty
                              ? 'Najprv vyber projekt.'
                              : _hasValidFlutterProject
                                  ? 'Flutter projekt je platný.'
                                  : 'Chýba pubspec.yaml.',
                          errorText: _projectPathController.text.trim().isNotEmpty &&
                                  !_hasValidFlutterProject
                              ? 'Vyber koreň Flutter projektu.'
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: taskRunning ? null : _pickFlutterProject,
                      icon: const Icon(Icons.folder_open_rounded),
                      label: const Text('VYBRAŤ PROJEKT'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'AGENT PIPELINE • PARALLEL ENGINE V1',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Kroky sa spúšťajú podľa závislostí. Nezávislé kroky môžu '
                        'bežať súčasne na rôznych agentoch.',
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: <Widget>[
                          FilterChip(
                            selected: _pipelineAnalyze,
                            onSelected: taskRunning ? null : (value) => setState(() => _pipelineAnalyze = value),
                            label: const Text('Flutter Analyze'),
                          ),
                          FilterChip(
                            selected: _pipelineTest,
                            onSelected: taskRunning ? null : (value) => setState(() => _pipelineTest = value),
                            label: const Text('Flutter Test'),
                          ),
                          FilterChip(
                            selected: _pipelineWindowsBuild,
                            onSelected: taskRunning ? null : (value) => setState(() => _pipelineWindowsBuild = value),
                            label: const Text('Windows Build'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ..._selectedPipelineSteps.map((step) {
                        final agents = _agentPool.agents
                            .where((candidate) =>
                                _scheduler.validate(candidate, step.type).isValid)
                            .toList(growable: false);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DropdownButtonFormField<String>(
                            initialValue: step.selectedAgentId == null ||
                                    step.selectedAgentId == _AgentPipelineStep.autoAgentId
                                ? _AgentPipelineStep.autoAgentId
                                : (agents.any((item) => item.id == step.selectedAgentId)
                                    ? step.selectedAgentId
                                    : _AgentPipelineStep.autoAgentId),
                            decoration: InputDecoration(
                              labelText: '${step.label} – agent',
                              prefixIcon: const Icon(Icons.computer_rounded),
                              helperText: step.selectedAgentId == null ||
                                      step.selectedAgentId == _AgentPipelineStep.autoAgentId
                                  ? 'AUTO vyberie dostupného kompatibilného agenta.'
                                  : null,
                            ),
                            items: <DropdownMenuItem<String>>[
                              const DropdownMenuItem<String>(
                                value: _AgentPipelineStep.autoAgentId,
                                child: Text('AUTO – najvhodnejší agent'),
                              ),
                              ...agents.map((item) => DropdownMenuItem<String>(
                                    value: item.id,
                                    child: Text('${item.name} • ${item.host}:${item.port}'),
                                  )),
                            ],
                            onChanged: taskRunning
                                ? null
                                : (value) => setState(() => step.selectedAgentId = value),
                          ),
                        );
                      }),
                      FilledButton.icon(
                        onPressed: taskRunning || !_hasValidFlutterProject
                            ? null
                            : _startPipelineWithAgentCheck,
                        icon: const Icon(Icons.playlist_play_rounded),
                        label: Text(_pipelineRunning ? 'PIPELINE BEŽÍ...' : 'SPUSTIŤ PIPELINE'),
                      ),
                      if (_pipelineSteps.any((step) => step.status != 'idle')) ...<Widget>[
                        const SizedBox(height: 12),
                        _AgentPipelineProgress(
                          steps: _pipelineSteps,
                          selectedCount: _selectedPipelineSteps.length,
                          startedAt: _pipelineStartedAt,
                          finishedAt: _pipelineFinishedAt,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: agent == null || taskRunning || !_hasValidFlutterProject
                          ? null
                          : _startAnalyze,
                      icon: const Icon(Icons.science_rounded),
                      label: Text(_startingTask ? 'ODOSIELAM...' : 'SPUSTIŤ FLUTTER ANALYZE'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: agent == null ||
                              !agent.supportsTest ||
                              taskRunning ||
                              !_hasValidFlutterProject
                          ? null
                          : _startTest,
                      icon: const Icon(Icons.fact_check_rounded),
                      label: const Text('SPUSTIŤ FLUTTER TEST'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: agent == null ||
                              !agent.supportsWindowsBuild ||
                              taskRunning ||
                              !_hasValidFlutterProject
                          ? null
                          : _startWindowsBuild,
                      icon: const Icon(Icons.desktop_windows_rounded),
                      label: const Text('BUILD WINDOWS RELEASE'),
                    ),
                  ],
                ),
                if (_task != null) ...<Widget>[
                  const SizedBox(height: 14),
                  _TaskCard(
                    task: _task!,
                    onCopyLog: _copyTaskLog,
                    onSaveLog: _saveTaskLog,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          RMSectionCard(
            title: 'Agent Pool & Scheduler',
            child: _agentPool.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Nie je pripojený žiadny agent. Spusti Local Agent alebo '
                        'zadaj IP adresu vzdialeného počítača.',
                      ),
                    ),
                  )
                : Column(
                    children: _agentPool.agents
                        .map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AgentCard(
                                agent: item,
                                pingText: item.id == agent?.id ? _pingText : '—',
                              ),
                            ))
                        .toList(growable: false),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AgentPipelineStep {
  _AgentPipelineStep({
    required this.type,
    required this.label,
    required this.dependencies,
  });

  static const String autoAgentId = '__auto__';

  final String type;
  final String label;
  final List<String> dependencies;
  String status = 'idle';
  RemoteAgentTask? task;
  String? selectedAgentId = autoAgentId;
  String? resolvedAgentName;
}

class _AgentPipelineProgress extends StatelessWidget {
  const _AgentPipelineProgress({
    required this.steps,
    required this.selectedCount,
    required this.startedAt,
    required this.finishedAt,
  });

  final List<_AgentPipelineStep> steps;
  final int selectedCount;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final active = steps.where((step) => step.status != 'disabled').toList();
    final completed = active.where((step) =>
        step.status == 'success' ||
        step.status == 'warnings' ||
        step.status == 'failed' ||
        step.status == 'skipped').length;
    final successCount = active.where((step) => step.status == 'success').length;
    final warningCount = active.where((step) => step.status == 'warnings').length;
    final failedCount = active.where((step) => step.status == 'failed').length;
    final skippedCount = active.where((step) => step.status == 'skipped').length;
    final progress = selectedCount == 0 ? 0.0 : completed / selectedCount;
    final end = finishedAt ?? DateTime.now();
    final totalDuration = startedAt == null ? Duration.zero : end.difference(startedAt!);
    final runningSteps = active.where((step) => step.status == 'running').toList();
    final finished = selectedCount > 0 && completed == selectedCount;
    final runningLabel = runningSteps.isEmpty
        ? null
        : runningSteps.length == 1
            ? 'BEŽÍ: ${runningSteps.first.label}'
            : 'BEŽIA SÚČASNE (${runningSteps.length}): '
                '${runningSteps.map((step) => step.label).join(', ')}';
    final overallLabel = failedCount > 0
        ? 'PIPELINE ZLYHALA'
        : finished
            ? warningCount > 0
                ? 'PIPELINE DOKONČENÁ S UPOZORNENIAMI'
                : 'PIPELINE ÚSPEŠNE DOKONČENÁ'
            : runningLabel ?? 'PIPELINE ČAKÁ NA SPLNENIE ZÁVISLOSTÍ';
    final overallColor = failedCount > 0
        ? Theme.of(context).colorScheme.error
        : finished && warningCount > 0
            ? Colors.amber
            : finished
                ? Colors.green
                : runningSteps.isNotEmpty
                    ? Colors.blue
                    : Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.dashboard_customize_rounded, color: overallColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PIPELINE EXECUTION DASHBOARD',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Text(
                '${(progress * 100).round()} %',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: overallColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress, minHeight: 9),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  overallLabel,
                  style: TextStyle(color: overallColor, fontWeight: FontWeight.w800),
                ),
              ),
              Text('$completed / $selectedCount krokov'),
              if (startedAt != null) ...<Widget>[
                const SizedBox(width: 12),
                Text(_formatDuration(totalDuration)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ...active.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final icon = switch (step.status) {
              'success' => Icons.check_circle_rounded,
              'warnings' => Icons.warning_amber_rounded,
              'failed' => Icons.error_rounded,
              'skipped' => Icons.skip_next_rounded,
              'running' => Icons.sync_rounded,
              _ => Icons.schedule_rounded,
            };
            final color = switch (step.status) {
              'success' => Colors.green,
              'warnings' => Colors.amber,
              'failed' => Theme.of(context).colorScheme.error,
              'running' => Colors.blue,
              _ => Theme.of(context).colorScheme.onSurfaceVariant,
            };
            final detail = switch (step.status) {
              'success' => 'Hotovo',
              'warnings' => 'Upozornenia',
              'failed' => 'Chyba',
              'skipped' => 'Preskočené',
              'running' => 'Beží',
              _ => 'Čaká',
            };
            final taskDuration = step.task?.startedAt == null
                ? null
                : (step.task?.finishedAt ?? DateTime.now().toUtc())
                    .difference(step.task!.startedAt!);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: step.status == 'running' ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: color.withValues(alpha: step.status == 'running' ? 0.65 : 0.25),
                ),
              ),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Text('${index + 1}', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  Icon(icon, size: 21, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(step.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                        if (step.resolvedAgentName != null)
                          Text(
                            'Agent: ${step.resolvedAgentName}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        Text(
                          step.dependencies.isEmpty
                              ? 'Závislosti: žiadne'
                              : 'Závislosti: ${step.dependencies.join(', ')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (taskDuration != null) ...<Widget>[
                    Text(_formatDuration(taskDuration), style: TextStyle(color: color)),
                    const SizedBox(width: 12),
                  ],
                  Text(detail, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                ],
              ),
            );
          }),
          if (finished) ...<Widget>[
            const Divider(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: <Widget>[
                _PipelineMetric(label: 'Hotovo', value: successCount, color: Colors.green),
                _PipelineMetric(label: 'Upozornenia', value: warningCount, color: Colors.amber),
                _PipelineMetric(
                  label: 'Chyby',
                  value: failedCount,
                  color: Theme.of(context).colorScheme.error,
                ),
                _PipelineMetric(
                  label: 'Preskočené',
                  value: skippedCount,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PipelineMetric extends StatelessWidget {
  const _PipelineMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label: $value', style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onCopyLog,
    required this.onSaveLog,
  });

  final RemoteAgentTask task;
  final VoidCallback onCopyLog;
  final VoidCallback onSaveLog;

  @override
  Widget build(BuildContext context) {
    final effectiveStatus = task.effectiveStatus;
    final color = switch (effectiveStatus) {
      'success' => Colors.green,
      'warnings' => Colors.amber,
      'failed' => Theme.of(context).colorScheme.error,
      'running' => Colors.blue,
      _ => Colors.blueGrey,
    };
    final label = switch (effectiveStatus) {
      'success' => 'HOTOVO',
      'warnings' => 'UPOZORNENIA',
      'failed' => 'CHYBA',
      'running' => 'BEŽÍ',
      _ => 'ČAKÁ',
    };
    final duration = task.startedAt == null
        ? null
        : (task.finishedAt ?? DateTime.now().toUtc()).difference(task.startedAt!);
    final logText = task.log.isEmpty ? 'Čakám na výstup agenta...' : task.log.join('\n');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                task.isSuccess
                    ? Icons.check_circle
                    : task.isWarning
                        ? Icons.warning_amber_rounded
                        : Icons.terminal_rounded,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.command,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Chip(label: Text(label)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Projekt: ${task.workingDirectory}'),
          Text('Exit code: ${task.exitCode?.toString() ?? '—'}'),
          if (task.isAnalyze && task.isFinished) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'Chyby: ${task.analyzeErrorCount}  •  '
              'Upozornenia: ${task.analyzeWarningCount}  •  '
              'Informácie: ${task.analyzeInfoCount}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (task.isWarning)
              const Text(
                'Analýza obsahuje iba odporúčania alebo upozornenia; nejde o chybu kompilácie.',
              ),
          ],
          if (duration != null) Text('Trvanie: ${duration.inSeconds} s'),
          if (task.error != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(task.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: task.log.isEmpty ? null : onCopyLog,
                icon: const Icon(Icons.copy_all_rounded, size: 18),
                label: const Text('KOPÍROVAŤ LOG'),
              ),
              OutlinedButton.icon(
                onPressed: task.log.isEmpty ? null : onSaveLog,
                icon: const Icon(Icons.save_alt_rounded, size: 18),
                label: const Text('ULOŽIŤ LOG'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              reverse: true,
              child: SelectableText(
                logText,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  const _AgentCard({required this.agent, required this.pingText});
  final RemoteAgent agent;
  final String pingText;

  @override
  Widget build(BuildContext context) {
    final online = agent.isOnline;
    final color = online ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(online ? Icons.cloud_done_rounded : Icons.cloud_off_rounded, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  agent.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Chip(
                label: Text(online ? 'ONLINE' : 'OFFLINE'),
                avatar: Icon(Icons.circle, size: 12, color: color),
              ),
            ],
          ),
          const Divider(height: 24),
          _line('Agent ID', agent.id),
          _line('Adresa', '${agent.host}:${agent.port}'),
          _line('Operačný systém', agent.operatingSystem),
          _line('Flutter', agent.flutterVersion),
          _line('Stav', agent.status.toUpperCase()),
          _line('Protokol', agent.protocolVersion.toString()),
          _line('Platformy', agent.platforms.isEmpty ? 'Nezistené' : agent.platforms.join(', ')),
          _line('Capabilities', agent.capabilities.isEmpty ? 'Nezistené' : agent.capabilities.join(', ')),
          _line('Posledný heartbeat', agent.lastSeen.toLocal().toString()),
          _line('Ping', pingText),
        ],
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 155,
              child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            Expanded(child: SelectableText(value)),
          ],
        ),
      );
}
