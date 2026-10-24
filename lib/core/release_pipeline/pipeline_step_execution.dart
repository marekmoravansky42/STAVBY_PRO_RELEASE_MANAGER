import 'pipeline_step.dart';

enum PipelineExecutionStatus {
  waiting,
  running,
  succeeded,
  failed,
  skipped,
  cancelled
}

/// Runtime state of one pipeline step. This is the single source of truth
/// used by the executor and the Execution Dashboard.
class PipelineStepExecution {
  const PipelineStepExecution({
    required this.step,
    required this.status,
    this.startedAt,
    this.finishedAt,
    this.message = '',
    this.exitCode,
    this.log = const <String>[],
    this.pluginId,
  });

  final PipelineStep step;
  final PipelineExecutionStatus status;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String message;
  final int? exitCode;
  final List<String> log;
  final String? pluginId;

  Duration get duration {
    final start = startedAt;
    if (start == null) return Duration.zero;
    return (finishedAt ?? DateTime.now()).difference(start);
  }

  bool get completed =>
      status == PipelineExecutionStatus.succeeded ||
      status == PipelineExecutionStatus.failed ||
      status == PipelineExecutionStatus.skipped ||
      status == PipelineExecutionStatus.cancelled;

  int get logLineCount => log.length;

  int get warningCount => log.where(_looksLikeWarning).length;

  int get errorCount => status == PipelineExecutionStatus.failed
      ? log.where(_looksLikeError).length
      : 0;

  String? get firstErrorLine {
    if (status != PipelineExecutionStatus.failed) return null;
    for (final line in log) {
      if (_looksLikeError(line)) return line.trim();
    }
    if (status == PipelineExecutionStatus.failed && message.trim().isNotEmpty) {
      return message.trim().split('\n').first;
    }
    return null;
  }

  String get fullLog => log.join('\n');

  PipelineStepExecution copyWith({
    PipelineExecutionStatus? status,
    DateTime? startedAt,
    DateTime? finishedAt,
    String? message,
    int? exitCode,
    List<String>? log,
    String? pluginId,
  }) {
    return PipelineStepExecution(
      step: step,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      message: message ?? this.message,
      exitCode: exitCode ?? this.exitCode,
      log: List<String>.unmodifiable(log ?? this.log),
      pluginId: pluginId ?? this.pluginId,
    );
  }

  static bool _looksLikeWarning(String line) {
    final value = line.toLowerCase();
    return value.contains('warning') ||
        value.contains('varovanie') ||
        value.contains('deprecated');
  }

  static bool _looksLikeError(String line) {
    final value = line.toLowerCase();
    return value.contains(' error ') ||
        value.startsWith('error') ||
        value.contains('chyba') ||
        value.contains('exception') ||
        value.contains('failed') ||
        value.contains('✖');
  }
}
