enum ReleaseStepStatus { waiting, running, succeeded, failed, skipped }

class ReleaseStepResult {
  const ReleaseStepResult({
    required this.id,
    required this.title,
    required this.status,
    required this.startedAt,
    required this.finishedAt,
    this.message = '',
  });

  final String id;
  final String title;
  final ReleaseStepStatus status;
  final DateTime startedAt;
  final DateTime finishedAt;
  final String message;

  bool get succeeded => status == ReleaseStepStatus.succeeded;
  Duration get duration => finishedAt.difference(startedAt);
}

class ReleaseStepDefinition {
  const ReleaseStepDefinition({
    required this.id,
    required this.title,
    required this.execute,
    this.enabled = true,
  });

  final String id;
  final String title;
  final bool enabled;
  final Future<String?> Function() execute;
}
