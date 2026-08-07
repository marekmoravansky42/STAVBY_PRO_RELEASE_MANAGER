enum AutomatedTestStatus { passed, failed, skipped }

class AutomatedTestResult {
  const AutomatedTestResult({
    required this.id,
    required this.title,
    required this.status,
    required this.startedAt,
    required this.finishedAt,
    this.message = '',
    this.critical = true,
  });

  final String id;
  final String title;
  final AutomatedTestStatus status;
  final DateTime startedAt;
  final DateTime finishedAt;
  final String message;
  final bool critical;

  Duration get duration => finishedAt.difference(startedAt);
  bool get passed => status == AutomatedTestStatus.passed;
  bool get blocksRelease => critical && status == AutomatedTestStatus.failed;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'title': title,
        'status': status.name,
        'critical': critical,
        'message': message,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt.toIso8601String(),
        'durationMs': duration.inMilliseconds,
      };
}
