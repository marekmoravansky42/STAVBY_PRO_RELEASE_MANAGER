class ExecutionHistoryEntry {
  const ExecutionHistoryEntry({
    required this.runId,
    required this.projectName,
    required this.projectPath,
    required this.pipelineName,
    required this.startedAt,
    required this.finishedAt,
    required this.succeededCount,
    required this.skippedCount,
    required this.failedCount,
    required this.cancelledCount,
  });

  final String runId;
  final String projectName;
  final String projectPath;
  final String pipelineName;
  final DateTime startedAt;
  final DateTime finishedAt;
  final int succeededCount;
  final int skippedCount;
  final int failedCount;
  final int cancelledCount;

  Duration get duration => finishedAt.difference(startedAt);
  bool get succeeded => failedCount == 0 && cancelledCount == 0;
  String get resultLabel => cancelledCount > 0 ? 'Zrušené' : failedCount > 0 ? 'Chyba' : 'Úspech';

  Map<String, Object?> toJson() => <String, Object?>{
    'runId': runId,
    'projectName': projectName,
    'projectPath': projectPath,
    'pipelineName': pipelineName,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt.toIso8601String(),
    'succeededCount': succeededCount,
    'skippedCount': skippedCount,
    'failedCount': failedCount,
    'cancelledCount': cancelledCount,
  };

  factory ExecutionHistoryEntry.fromJson(Map<String, Object?> json) => ExecutionHistoryEntry(
    runId: json['runId'] as String,
    projectName: json['projectName'] as String,
    projectPath: json['projectPath'] as String,
    pipelineName: json['pipelineName'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    finishedAt: DateTime.parse(json['finishedAt'] as String),
    succeededCount: (json['succeededCount'] as num?)?.toInt() ?? 0,
    skippedCount: (json['skippedCount'] as num?)?.toInt() ?? 0,
    failedCount: (json['failedCount'] as num?)?.toInt() ?? 0,
    cancelledCount: (json['cancelledCount'] as num?)?.toInt() ?? 0,
  );
}
