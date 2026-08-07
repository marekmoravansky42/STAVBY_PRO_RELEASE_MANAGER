import '../release/release_report.dart';
import '../release/release_step.dart';
import 'logger_service.dart';

/// Executes a release pipeline sequentially and stops safely on the first
/// failed quality gate. UI code can observe each state transition through
/// [onStepChanged].
class ReleaseEngine {
  const ReleaseEngine({this.logger = const LoggerService()});

  final LoggerService logger;

  Future<ReleaseReport> run({
    required String version,
    required int build,
    required List<ReleaseStepDefinition> steps,
    void Function(ReleaseStepResult result)? onStepChanged,
  }) async {
    final pipelineStartedAt = DateTime.now();
    final results = <ReleaseStepResult>[];
    var pipelineFailed = false;

    for (final step in steps) {
      if (!step.enabled || pipelineFailed) {
        final now = DateTime.now();
        final skipped = ReleaseStepResult(
          id: step.id,
          title: step.title,
          status: ReleaseStepStatus.skipped,
          startedAt: now,
          finishedAt: now,
          message: pipelineFailed
              ? 'Preskočené po zlyhaní predchádzajúceho kroku.'
              : 'Krok je vypnutý.',
        );
        results.add(skipped);
        onStepChanged?.call(skipped);
        continue;
      }

      final startedAt = DateTime.now();
      onStepChanged?.call(ReleaseStepResult(
        id: step.id,
        title: step.title,
        status: ReleaseStepStatus.running,
        startedAt: startedAt,
        finishedAt: startedAt,
      ));

      try {
        final message = await step.execute();
        final succeeded = ReleaseStepResult(
          id: step.id,
          title: step.title,
          status: ReleaseStepStatus.succeeded,
          startedAt: startedAt,
          finishedAt: DateTime.now(),
          message: message ?? '',
        );
        results.add(succeeded);
        onStepChanged?.call(succeeded);
      } catch (error) {
        pipelineFailed = true;
        final failed = ReleaseStepResult(
          id: step.id,
          title: step.title,
          status: ReleaseStepStatus.failed,
          startedAt: startedAt,
          finishedAt: DateTime.now(),
          message: error.toString(),
        );
        results.add(failed);
        onStepChanged?.call(failed);
      }
    }

    final report = ReleaseReport(
      version: version,
      build: build,
      startedAt: pipelineStartedAt,
      finishedAt: DateTime.now(),
      steps: List<ReleaseStepResult>.unmodifiable(results),
    );

    await logger.write(
      fileName: 'release_engine.log',
      message: '${report.toText()}\n',
    );
    return report;
  }
}
