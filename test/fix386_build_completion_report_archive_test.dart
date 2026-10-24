import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stavby_pro_release_manager/services/build_completion_report_archive_service.dart';

Future<List<File>> archivesFor(Directory reports, int build) async {
  final prefix = 'BUILD_${build}_COMPLETION_REPORT_ARCHIVE_';
  final files = <File>[];
  await for (final entry in reports.list()) {
    if (entry is File && path.basename(entry.path).startsWith(prefix)) {
      files.add(entry);
    }
  }
  files.sort((left, right) => left.path.compareTo(right.path));
  return files;
}

void main() {
  test(
      'Build Completion Report keeps the latest file and bounded prior reports',
      () async {
    final root = await Directory.systemTemp.createTemp('fix386_reports_');
    addTearDown(() => root.delete(recursive: true));
    final reports = Directory(path.join(root.path, 'build_completion_reports'));
    await reports.create();
    final canonical =
        File(path.join(reports.path, 'BUILD_333_COMPLETION_REPORT.md'));

    await archiveExistingBuildCompletionReport(
      reportsDirectory: reports,
      build: 333,
      canonicalReport: canonical,
      now: () => DateTime(2026, 9, 8, 10),
    );
    await canonical.writeAsString('first completion');
    expect(await archivesFor(reports, 333), isEmpty);
    expect(await canonical.readAsString(), 'first completion');

    await archiveExistingBuildCompletionReport(
      reportsDirectory: reports,
      build: 333,
      canonicalReport: canonical,
      now: () => DateTime(2026, 9, 8, 10, 0, 1),
    );
    await canonical.writeAsString('second completion');
    var archives = await archivesFor(reports, 333);
    expect(archives, hasLength(1));
    expect(await archives.single.readAsString(), 'first completion');
    expect(await canonical.readAsString(), 'second completion');

    final otherBuild =
        File(path.join(reports.path, 'BUILD_334_COMPLETION_REPORT.md'));
    await otherBuild.writeAsString('other build');
    final otherArchive = File(path.join(reports.path,
        'BUILD_334_COMPLETION_REPORT_ARCHIVE_20260908_100000_000_001.md'));
    await otherArchive.writeAsString('other build archive');

    for (var second = 2; second <= 11; second++) {
      await archiveExistingBuildCompletionReport(
        reportsDirectory: reports,
        build: 333,
        canonicalReport: canonical,
        now: () => DateTime(2026, 9, 8, 10, 0, second),
      );
      await canonical.writeAsString('completion $second');
    }

    archives = await archivesFor(reports, 333);
    expect(archives, hasLength(buildCompletionReportArchiveLimit));
    expect(path.basename(archives.first.path),
        'BUILD_333_COMPLETION_REPORT_ARCHIVE_20260908_100002_000_001.md');
    expect(await canonical.readAsString(), 'completion 11');
    expect(await otherBuild.readAsString(), 'other build');
    expect(await otherArchive.readAsString(), 'other build archive');
  });
}
