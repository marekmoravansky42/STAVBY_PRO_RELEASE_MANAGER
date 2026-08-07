import 'dart:async';
import 'dart:convert';
import 'dart:io';

class AgentTask {
  AgentTask({
    required this.id,
    required this.command,
    required this.workingDirectory,
  }) : createdAt = DateTime.now().toUtc();

  final String id;
  final String command;
  final String workingDirectory;
  final DateTime createdAt;
  DateTime? startedAt;
  DateTime? finishedAt;
  String status = 'queued';
  int? exitCode;
  String? error;
  final List<String> log = <String>[];

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'command': command,
        'workingDirectory': workingDirectory,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'startedAt': startedAt?.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'exitCode': exitCode,
        'error': error,
        'log': log,
      };
}

Future<String> _flutterVersion() async {
  try {
    final result = await Process.run(
      'flutter',
      const <String>['--version', '--machine'],
      runInShell: true,
    );
    if (result.exitCode == 0) {
      final data = jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
      return data['frameworkVersion']?.toString() ?? 'Nezistené';
    }
  } catch (_) {}
  return 'Nedostupné';
}

List<String> _platforms() {
  final result = <String>[];
  if (Platform.isWindows) result.addAll(const <String>['Windows', 'Android', 'Web']);
  if (Platform.isLinux) result.addAll(const <String>['Linux', 'Android', 'Web']);
  if (Platform.isMacOS) result.addAll(const <String>['macOS', 'iOS', 'Android', 'Web']);
  return result;
}

Future<Map<String, dynamic>> _readJsonBody(HttpRequest request) async {
  final body = await utf8.decoder.bind(request).join();
  if (body.trim().isEmpty) return <String, dynamic>{};
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Očakáva sa JSON objekt.');
  }
  return decoded;
}

Future<void> _executeFlutterCommand(
  AgentTask task,
  List<String> arguments,
) async {
  task
    ..status = 'running'
    ..startedAt = DateTime.now().toUtc()
    ..log.add('▶ ${task.command}');

  try {
    final project = Directory(task.workingDirectory);
    if (!await project.exists()) {
      throw FileSystemException('Pracovný priečinok neexistuje.', project.path);
    }
    if (!await File('${project.path}${Platform.pathSeparator}pubspec.yaml').exists()) {
      throw FileSystemException('V pracovnom priečinku chýba pubspec.yaml.', project.path);
    }

    final process = await Process.start(
      'flutter',
      arguments,
      workingDirectory: project.path,
      runInShell: true,
    );

    final stdoutDone = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach(task.log.add);
    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach(task.log.add);

    final exitCode = await process.exitCode;
    await Future.wait<void>(<Future<void>>[stdoutDone, stderrDone]);
    task
      ..exitCode = exitCode
      ..status = exitCode == 0 ? 'success' : 'failed'
      ..finishedAt = DateTime.now().toUtc()
      ..log.add(exitCode == 0
          ? '✔ ${task.command} dokončený.'
          : '✖ ${task.command} zlyhal (exit code $exitCode).');
  } catch (error) {
    task
      ..status = 'failed'
      ..exitCode = -1
      ..error = error.toString()
      ..finishedAt = DateTime.now().toUtc()
      ..log.add('✖ $error');
  }
}

Future<void> _writeJson(
  HttpRequest request,
  int statusCode,
  Map<String, dynamic> body,
) async {
  try {
    request.response.statusCode = statusCode;
    request.response.headers.contentType = ContentType.json;
    request.response.headers.set('Access-Control-Allow-Origin', '*');
    request.response.headers.set('Access-Control-Allow-Headers', 'Content-Type');
    request.response.headers.set(
      'Access-Control-Allow-Methods',
      'GET, POST, OPTIONS',
    );
    if (statusCode != HttpStatus.noContent) {
      request.response.write(jsonEncode(body));
    }
  } catch (error, stackTrace) {
    stderr.writeln('Chyba pri príprave HTTP odpovede: $error');
    stderr.writeln(stackTrace);
  } finally {
    try {
      await request.response.close();
    } catch (error) {
      // Odpojenie klienta počas odpovede nesmie ukončiť Release Agent.
      stderr.writeln('Klient prerušil HTTP odpoveď: $error');
    }
  }
}

Future<void> _handleRequest(
  HttpRequest request,
  String name,
  String flutter,
  int port,
  Map<String, AgentTask> tasks,
) async {
  try {
    if (request.method == 'OPTIONS') {
      await _writeJson(request, HttpStatus.noContent, const <String, dynamic>{});
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/status') {
      await _writeJson(request, HttpStatus.ok, <String, dynamic>{
        'id': '$name-$port',
        'protocolVersion': 4,
        'capabilities': const <String>[
          'status',
          'ping',
          'flutter_analyze',
          'flutter_test',
          'flutter_build_windows',
        ],
        'name': name,
        'operatingSystem':
            '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        'flutterVersion': flutter,
        'platforms': _platforms(),
        'status': tasks.values.any((task) => task.status == 'running')
            ? 'busy'
            : 'idle',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/ping') {
      await _writeJson(request, HttpStatus.ok, <String, dynamic>{
        'ok': true,
        'nonce': request.uri.queryParameters['nonce'],
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/tasks/analyze') {
      final body = await _readJsonBody(request);
      final workingDirectory =
          body['workingDirectory']?.toString().trim() ?? '';
      if (workingDirectory.isEmpty) {
        await _writeJson(request, HttpStatus.badRequest, <String, dynamic>{
          'error': 'Chýba workingDirectory.',
        });
        return;
      }
      if (tasks.values.any((task) => task.status == 'running')) {
        await _writeJson(request, HttpStatus.conflict, <String, dynamic>{
          'error': 'Agent už vykonáva inú úlohu.',
        });
        return;
      }

      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final task = AgentTask(
        id: id,
        command: 'flutter analyze',
        workingDirectory: workingDirectory,
      );
      tasks[id] = task;
      unawaited(_executeFlutterCommand(task, const <String>['analyze']));
      await _writeJson(request, HttpStatus.accepted, task.toJson());
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/tasks/test') {
      final body = await _readJsonBody(request);
      final workingDirectory =
          body['workingDirectory']?.toString().trim() ?? '';
      if (workingDirectory.isEmpty) {
        await _writeJson(request, HttpStatus.badRequest, <String, dynamic>{
          'error': 'Chýba workingDirectory.',
        });
        return;
      }
      if (tasks.values.any((task) => task.status == 'running')) {
        await _writeJson(request, HttpStatus.conflict, <String, dynamic>{
          'error': 'Agent už vykonáva inú úlohu.',
        });
        return;
      }

      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final task = AgentTask(
        id: id,
        command: 'flutter test',
        workingDirectory: workingDirectory,
      );
      tasks[id] = task;
      unawaited(_executeFlutterCommand(task, const <String>['test']));
      await _writeJson(request, HttpStatus.accepted, task.toJson());
      return;
    }


    if (request.method == 'POST' && request.uri.path == '/tasks/build/windows') {
      final body = await _readJsonBody(request);
      final workingDirectory =
          body['workingDirectory']?.toString().trim() ?? '';
      if (workingDirectory.isEmpty) {
        await _writeJson(request, HttpStatus.badRequest, <String, dynamic>{
          'error': 'Chýba workingDirectory.',
        });
        return;
      }
      if (!Platform.isWindows) {
        await _writeJson(request, HttpStatus.badRequest, <String, dynamic>{
          'error': 'Windows build je podporovaný iba na Windows agentovi.',
        });
        return;
      }
      if (tasks.values.any((task) => task.status == 'running')) {
        await _writeJson(request, HttpStatus.conflict, <String, dynamic>{
          'error': 'Agent už vykonáva inú úlohu.',
        });
        return;
      }

      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final task = AgentTask(
        id: id,
        command: 'flutter build windows --release',
        workingDirectory: workingDirectory,
      );
      tasks[id] = task;
      unawaited(_executeFlutterCommand(
        task,
        const <String>['build', 'windows', '--release'],
      ));
      await _writeJson(request, HttpStatus.accepted, task.toJson());
      return;
    }

    if (request.method == 'GET' &&
        request.uri.pathSegments.length == 2 &&
        request.uri.pathSegments.first == 'tasks') {
      final task = tasks[request.uri.pathSegments[1]];
      if (task == null) {
        await _writeJson(request, HttpStatus.notFound, <String, dynamic>{
          'error': 'Úloha neexistuje.',
        });
      } else {
        await _writeJson(request, HttpStatus.ok, task.toJson());
      }
      return;
    }

    await _writeJson(request, HttpStatus.notFound, <String, dynamic>{
      'error': 'Not found',
    });
  } catch (error, stackTrace) {
    stderr.writeln('Chyba pri spracovaní ${request.method} ${request.uri}: $error');
    stderr.writeln(stackTrace);
    await _writeJson(request, HttpStatus.internalServerError, <String, dynamic>{
      'error': error.toString(),
    });
  }
}

Future<void> _runAgent(List<String> args) async {
  String? portArgument;
  for (final value in args) {
    if (!value.startsWith('--')) {
      portArgument = value;
      break;
    }
  }
  final port = portArgument == null ? 47834 : int.tryParse(portArgument) ?? 47834;
  final localOnly = args.contains('--local');
  final address = localOnly
      ? InternetAddress.loopbackIPv4
      : InternetAddress.anyIPv4;

  stdout.writeln(
    'Spúšťam Release Agent na ${address.address}:$port '
    '(${localOnly ? 'LOCAL' : 'LAN'} režim)...',
  );

  late final HttpServer server;
  try {
    server = await HttpServer.bind(
      address,
      port,
      shared: false,
    );
  } on SocketException catch (error, stackTrace) {
    stderr.writeln('BIND_CHYBA: ${address.address}:$port');
    stderr.writeln(error);
    stderr.writeln(stackTrace);
    rethrow;
  }
  final name = Platform.localHostname;
  final flutter = await _flutterVersion();
  final tasks = <String, AgentTask>{};

  stdout.writeln('STAVBY PRO Release Agent počúva na ${address.address}:$port');
  stdout.writeln('Počítač: $name • Flutter: $flutter');

  await for (final request in server) {
    // Každá požiadavka je izolovaná. Jej chyba nesmie zastaviť server.
    unawaited(_handleRequest(request, name, flutter, port, tasks));
  }
}

Future<void> main(List<String> args) async {
  await runZonedGuarded<Future<void>>(
    () => _runAgent(args),
    (error, stackTrace) {
      stderr.writeln('NEOČAKÁVANÁ CHYBA RELEASE AGENTA: $error');
      stderr.writeln(stackTrace);
      exitCode = 1;
    },
  );
}
