import 'dart:convert';

import 'test_result.dart';

class QualityReport {
  const QualityReport({
    required this.projectName,
    required this.version,
    required this.build,
    required this.startedAt,
    required this.finishedAt,
    required this.results,
  });

  final String projectName;
  final String version;
  final int build;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<AutomatedTestResult> results;

  Duration get duration => finishedAt.difference(startedAt);
  int get passedCount => results.where((result) => result.status == AutomatedTestStatus.passed).length;
  int get failedCount => results.where((result) => result.status == AutomatedTestStatus.failed).length;
  int get skippedCount => results.where((result) => result.status == AutomatedTestStatus.skipped).length;
  bool get qualityGatePassed => !results.any((result) => result.blocksRelease);

  Map<String, Object?> toJson() => <String, Object?>{
        'projectName': projectName,
        'version': version,
        'build': build,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt.toIso8601String(),
        'durationMs': duration.inMilliseconds,
        'qualityGatePassed': qualityGatePassed,
        'summary': <String, int>{
          'passed': passedCount,
          'failed': failedCount,
          'skipped': skippedCount,
          'total': results.length,
        },
        'results': results.map((result) => result.toJson()).toList(growable: false),
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  String toText() {
    final buffer = StringBuffer()
      ..writeln('STAVBY PRO Release Manager - Quality Report')
      ..writeln('Project: $projectName')
      ..writeln('Version: $version+$build')
      ..writeln('Started: ${startedAt.toIso8601String()}')
      ..writeln('Finished: ${finishedAt.toIso8601String()}')
      ..writeln('Duration: ${duration.inMilliseconds} ms')
      ..writeln('Quality Gate: ${qualityGatePassed ? 'PASS' : 'FAIL'}')
      ..writeln('Results: $passedCount PASS / $failedCount FAIL / $skippedCount SKIPPED')
      ..writeln();

    for (final result in results) {
      buffer
        ..writeln('[${result.status.name.toUpperCase()}] ${result.title}')
        ..writeln('  Critical: ${result.critical ? 'yes' : 'no'}')
        ..writeln('  Duration: ${result.duration.inMilliseconds} ms');
      if (result.message.trim().isNotEmpty) {
        buffer.writeln('  ${result.message.trim().replaceAll('\n', '\n  ')}');
      }
    }
    return buffer.toString();
  }
}
