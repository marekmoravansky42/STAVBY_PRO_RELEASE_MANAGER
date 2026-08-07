import 'dart:io';

import '../testing/automated_test.dart';
import '../testing/quality_report.dart';
import '../testing/test_result.dart';
import 'logger_service.dart';

/// Executes project checks sequentially and produces machine-readable and
/// human-readable quality reports. A failed critical check blocks release.
class TestRunnerService {
  const TestRunnerService({this.logger = const LoggerService()});

  final LoggerService logger;

  Future<QualityReport> run({
    required String projectName,
    required String version,
    required int build,
    required List<AutomatedTestDefinition> tests,
    required String reportDirectory,
    void Function(AutomatedTestResult result)? onResultChanged,
  }) async {
    final startedAt = DateTime.now();
    final results = <AutomatedTestResult>[];
    var blocked = false;

    for (final test in tests) {
      if (!test.enabled || blocked) {
        final now = DateTime.now();
        final skipped = AutomatedTestResult(
          id: test.id,
          title: test.title,
          status: AutomatedTestStatus.skipped,
          startedAt: now,
          finishedAt: now,
          critical: test.critical,
          message: blocked
              ? 'Preskočené po zlyhaní kritickej kontroly.'
              : 'Kontrola je vypnutá.',
        );
        results.add(skipped);
        onResultChanged?.call(skipped);
        continue;
      }

      final testStartedAt = DateTime.now();
      try {
        final message = await test.execute();
        final passed = AutomatedTestResult(
          id: test.id,
          title: test.title,
          status: AutomatedTestStatus.passed,
          startedAt: testStartedAt,
          finishedAt: DateTime.now(),
          critical: test.critical,
          message: message ?? '',
        );
        results.add(passed);
        onResultChanged?.call(passed);
      } catch (error) {
        final failed = AutomatedTestResult(
          id: test.id,
          title: test.title,
          status: AutomatedTestStatus.failed,
          startedAt: testStartedAt,
          finishedAt: DateTime.now(),
          critical: test.critical,
          message: error.toString(),
        );
        results.add(failed);
        onResultChanged?.call(failed);
        blocked = failed.blocksRelease;
      }
    }

    final report = QualityReport(
      projectName: projectName,
      version: version,
      build: build,
      startedAt: startedAt,
      finishedAt: DateTime.now(),
      results: List<AutomatedTestResult>.unmodifiable(results),
    );

    await _writeReports(reportDirectory, report);
    await logger.write(
      fileName: 'quality_gate.log',
      message: '${report.toText()}\n',
    );
    return report;
  }

  Future<void> _writeReports(String directoryPath, QualityReport report) async {
    final directory = Directory(directoryPath);
    await directory.create(recursive: true);
    await File('${directory.path}${Platform.pathSeparator}quality_report.json')
        .writeAsString(report.toPrettyJson());
    await File('${directory.path}${Platform.pathSeparator}quality_report.txt')
        .writeAsString(report.toText());
  }
}
