import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'agent_api.dart';
import 'remote_agent.dart';

class AgentPingResult {
  const AgentPingResult({required this.ok, required this.latencyMs, required this.message});
  final bool ok;
  final int latencyMs;
  final String message;
}

class RemoteAgentTask {
  const RemoteAgentTask({
    required this.id,
    required this.command,
    required this.workingDirectory,
    required this.status,
    required this.log,
    this.exitCode,
    this.error,
    this.startedAt,
    this.finishedAt,
  });

  final String id;
  final String command;
  final String workingDirectory;
  final String status;
  final List<String> log;
  final int? exitCode;
  final String? error;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  bool get isFinished => status == 'success' || status == 'failed';

  bool get isAnalyze => command.trim().toLowerCase() == 'flutter analyze';

  int get analyzeErrorCount => _countAnalyzeSeverity('error');
  int get analyzeWarningCount => _countAnalyzeSeverity('warning');
  int get analyzeInfoCount => _countAnalyzeSeverity('info');

  int _countAnalyzeSeverity(String severity) {
    final pattern = RegExp(r'^\s*' + severity + r'\s+-\s+', caseSensitive: false);
    return log.where((line) => pattern.hasMatch(line)).length;
  }

  bool get hasAnalyzeNotices =>
      isAnalyze && analyzeErrorCount == 0 &&
      (analyzeWarningCount > 0 || analyzeInfoCount > 0);

  String get effectiveStatus {
    if (status == 'failed' && error == null && hasAnalyzeNotices) {
      return 'warnings';
    }
    return status;
  }

  bool get isSuccess => effectiveStatus == 'success';
  bool get isWarning => effectiveStatus == 'warnings';

  factory RemoteAgentTask.fromJson(Map<String, dynamic> json) => RemoteAgentTask(
        id: json['id']?.toString() ?? '',
        command: json['command']?.toString() ?? '',
        workingDirectory: json['workingDirectory']?.toString() ?? '',
        status: json['status']?.toString() ?? 'queued',
        log: (json['log'] as List<dynamic>? ?? const <dynamic>[])
            .map((line) => line.toString())
            .toList(growable: false),
        exitCode: json['exitCode'] is num ? (json['exitCode'] as num).toInt() : null,
        error: json['error']?.toString(),
        startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? ''),
        finishedAt: DateTime.tryParse(json['finishedAt']?.toString() ?? ''),
      );
}

class RemoteAgentService {
  const RemoteAgentService();

  Future<Map<String, dynamic>> _readJsonResponse(HttpClientResponse response) async {
    final body = await utf8.decoder.bind(response).join();
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Agent vrátil neplatnú JSON odpoveď.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(decoded['error']?.toString() ?? 'HTTP ${response.statusCode}');
    }
    return decoded;
  }

  Future<RemoteAgent> readStatus(String host, {int port = AgentApi.defaultPort}) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final request = await client.getUrl(Uri.parse('http://$host:$port${AgentApi.status}'));
      final response = await request.close().timeout(const Duration(seconds: 4));
      final json = await _readJsonResponse(response);
      return RemoteAgent.fromJson(json, host: host, port: port);
    } finally {
      client.close(force: true);
    }
  }

  Future<AgentPingResult> ping(String host, {int port = AgentApi.defaultPort}) async {
    final stopwatch = Stopwatch()..start();
    final nonce = Random.secure().nextInt(1 << 31);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final request = await client.getUrl(Uri.parse('http://$host:$port${AgentApi.ping}?nonce=$nonce'));
      final response = await request.close().timeout(const Duration(seconds: 4));
      final json = await _readJsonResponse(response);
      stopwatch.stop();
      final echoed = int.tryParse(json['nonce']?.toString() ?? '');
      final ok = echoed == nonce;
      return AgentPingResult(
        ok: ok,
        latencyMs: stopwatch.elapsedMilliseconds,
        message: ok ? 'Spojenie je funkčné.' : 'Agent vrátil neplatnú odpoveď.',
      );
    } catch (error) {
      stopwatch.stop();
      return AgentPingResult(ok: false, latencyMs: stopwatch.elapsedMilliseconds, message: error.toString());
    } finally {
      client.close(force: true);
    }
  }

  Future<RemoteAgentTask> startAnalyze(
    String host, {
    int port = AgentApi.defaultPort,
    required String workingDirectory,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final request = await client.postUrl(Uri.parse('http://$host:$port${AgentApi.analyzeTasks}'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(<String, dynamic>{'workingDirectory': workingDirectory}));
      final response = await request.close().timeout(const Duration(seconds: 6));
      return RemoteAgentTask.fromJson(await _readJsonResponse(response));
    } finally {
      client.close(force: true);
    }
  }

  Future<RemoteAgentTask> startTest(
    String host, {
    int port = AgentApi.defaultPort,
    required String workingDirectory,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final request = await client.postUrl(Uri.parse('http://$host:$port${AgentApi.testTasks}'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(<String, dynamic>{'workingDirectory': workingDirectory}));
      final response = await request.close().timeout(const Duration(seconds: 6));
      return RemoteAgentTask.fromJson(await _readJsonResponse(response));
    } finally {
      client.close(force: true);
    }
  }


  Future<RemoteAgentTask> startWindowsBuild(
    String host, {
    int port = AgentApi.defaultPort,
    required String workingDirectory,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final request = await client.postUrl(
        Uri.parse('http://$host:$port${AgentApi.windowsBuildTasks}'),
      );
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(<String, dynamic>{'workingDirectory': workingDirectory}));
      final response = await request.close().timeout(const Duration(seconds: 6));
      return RemoteAgentTask.fromJson(await _readJsonResponse(response));
    } finally {
      client.close(force: true);
    }
  }

  Future<RemoteAgentTask> readTask(
    String host,
    String taskId, {
    int port = AgentApi.defaultPort,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final request = await client.getUrl(Uri.parse('http://$host:$port${AgentApi.task(taskId)}'));
      final response = await request.close().timeout(const Duration(seconds: 5));
      return RemoteAgentTask.fromJson(await _readJsonResponse(response));
    } finally {
      client.close(force: true);
    }
  }
}
