import 'release_step.dart';

class ReleaseReport {
  const ReleaseReport({
    required this.version,
    required this.build,
    required this.startedAt,
    required this.finishedAt,
    required this.steps,
  });

  final String version;
  final int build;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<ReleaseStepResult> steps;

  bool get succeeded => steps.every(
        (step) => step.status == ReleaseStepStatus.succeeded ||
            step.status == ReleaseStepStatus.skipped,
      );

  Duration get duration => finishedAt.difference(startedAt);

  String toText() {
    final buffer = StringBuffer()
      ..writeln('STAVBY PRO Release Manager – Release Report')
      ..writeln('Version: $version+$build')
      ..writeln('Started: ${startedAt.toIso8601String()}')
      ..writeln('Finished: ${finishedAt.toIso8601String()}')
      ..writeln('Duration: ${duration.inSeconds}s')
      ..writeln('Status: ${succeeded ? 'SUCCESS' : 'FAILED'}')
      ..writeln();

    for (final step in steps) {
      buffer.writeln(
        '${step.title}: ${step.status.name.toUpperCase()}'
        '${step.message.isEmpty ? '' : ' – ${step.message}'}',
      );
    }
    return buffer.toString();
  }
}
