export 'pipeline_step_execution.dart';
export 'pipeline_execution_summary.dart';

import 'dart:io';

import 'pipeline_step.dart';
import 'pipeline_step_execution.dart';
import 'pipeline_template.dart';
import 'pipeline_validator.dart';

typedef PipelineAction = Future<String?> Function(PipelineStep step);
typedef PipelineSkipReason = String? Function(PipelineStep step);
typedef PipelineCancellationCheck = bool Function();

class PipelineExecutionReport {
  const PipelineExecutionReport({
    required this.template,
    required this.startedAt,
    required this.finishedAt,
    required this.steps,
  });

  final PipelineTemplate template;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<PipelineStepExecution> steps;
  bool get succeeded => steps.every((result) =>
      result.status == PipelineExecutionStatus.succeeded ||
      result.status == PipelineExecutionStatus.skipped);
}

/// Runs a declarative template through registered action handlers.
class PipelineExecutor {
  PipelineExecutor({
    required Map<String, PipelineAction> actions,
    PipelineValidator validator = const PipelineValidator(),
    PipelineSkipReason? skipReason,
    PipelineCancellationCheck? shouldCancel,
  })  : _actions = Map<String, PipelineAction>.unmodifiable(actions),
        _validator = validator,
        _skipReason = skipReason,
        _shouldCancel = shouldCancel;

  final Map<String, PipelineAction> _actions;
  final PipelineValidator _validator;
  final PipelineSkipReason? _skipReason;
  final PipelineCancellationCheck? _shouldCancel;

  Future<PipelineExecutionReport> run(
    PipelineTemplate template, {
    void Function(PipelineStepExecution result)? onStepChanged,
  }) async {
    _validator.requireValid(template);
    final startedAt = DateTime.now();
    final results = <PipelineStepExecution>[];
    var stop = false;

    for (final step in template.steps) {
      if (_shouldCancel?.call() ?? false) {
        final now = DateTime.now();
        final cancelled = PipelineStepExecution(
          step: step,
          status: PipelineExecutionStatus.cancelled,
          startedAt: now,
          finishedAt: now,
          message: 'Pipeline bola zrušená používateľom.',
        );
        results.add(cancelled);
        onStepChanged?.call(cancelled);
        continue;
      }
      if (!step.enabled || stop) {
        final now = DateTime.now();
        final skipped = PipelineStepExecution(
          step: step,
          status: PipelineExecutionStatus.skipped,
          startedAt: now,
          finishedAt: now,
          message: !step.enabled
              ? 'Krok je vypnutý.'
              : 'Preskočené po zlyhaní predchádzajúceho kroku.',
        );
        results.add(skipped);
        onStepChanged?.call(skipped);
        continue;
      }

      final unsupportedReason = _skipReason?.call(step);
      if (unsupportedReason != null) {
        final now = DateTime.now();
        final skipped = PipelineStepExecution(
          step: step,
          status: PipelineExecutionStatus.skipped,
          startedAt: now,
          finishedAt: now,
          message: unsupportedReason,
        );
        results.add(skipped);
        onStepChanged?.call(skipped);
        continue;
      }

      final action = _actions[step.action];
      final stepStartedAt = DateTime.now();
      onStepChanged?.call(PipelineStepExecution(
        step: step,
        status: PipelineExecutionStatus.running,
        startedAt: stepStartedAt,
      ));

      try {
        if (action == null) {
          throw StateError('Akcia pipeline nie je registrovaná: ${step.action}');
        }
        final message = await action(step);
        final succeeded = PipelineStepExecution(
          step: step,
          status: PipelineExecutionStatus.succeeded,
          startedAt: stepStartedAt,
          finishedAt: DateTime.now(),
          message: message ?? '',
          exitCode: 0,
        );
        results.add(succeeded);
        onStepChanged?.call(succeeded);
      } catch (error) {
        if (_shouldCancel?.call() ?? false) {
          final cancelled = PipelineStepExecution(
            step: step,
            status: PipelineExecutionStatus.cancelled,
            startedAt: stepStartedAt,
            finishedAt: DateTime.now(),
            message: 'Pipeline bola zrušená používateľom.',
          );
          results.add(cancelled);
          onStepChanged?.call(cancelled);
          stop = true;
          continue;
        }
        final failed = PipelineStepExecution(
          step: step,
          status: PipelineExecutionStatus.failed,
          startedAt: stepStartedAt,
          finishedAt: DateTime.now(),
          message: error.toString(),
          exitCode: error is ProcessException ? error.errorCode : null,
        );
        results.add(failed);
        onStepChanged?.call(failed);
        stop = !step.continueOnFailure;
      }
    }

    return PipelineExecutionReport(
      template: template,
      startedAt: startedAt,
      finishedAt: DateTime.now(),
      steps: List<PipelineStepExecution>.unmodifiable(results),
    );
  }
}
