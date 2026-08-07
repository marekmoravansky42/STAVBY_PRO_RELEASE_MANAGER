import 'pipeline_step_execution.dart';

/// Immutable summary of one complete pipeline run.
class PipelineExecutionSummary {
  const PipelineExecutionSummary({
    required this.runId,
    required this.projectName,
    required this.projectPath,
    required this.pipelineName,
    required this.startedAt,
    required this.finishedAt,
    required this.platformLabels,
    required this.steps,
    required this.pluginIds,
  });

  final String runId;
  final String projectName;
  final String projectPath;
  final String pipelineName;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<String> platformLabels;
  final List<PipelineStepExecution> steps;
  final Set<String> pluginIds;

  Duration get duration => finishedAt.difference(startedAt);

  int count(PipelineExecutionStatus status) =>
      steps.where((step) => step.status == status).length;

  int get succeededCount => count(PipelineExecutionStatus.succeeded);
  int get skippedCount => count(PipelineExecutionStatus.skipped);
  int get failedCount => count(PipelineExecutionStatus.failed);
  int get cancelledCount => count(PipelineExecutionStatus.cancelled);
  int get pluginCount => pluginIds.length;
  bool get succeeded => failedCount == 0 && cancelledCount == 0;
}
