import 'dart:io';

import 'package:path/path.dart' as path;

const int buildCompletionReportArchiveLimit = 10;

Future<void> archiveExistingBuildCompletionReport({
  required Directory reportsDirectory,
  required Object? build,
  required File canonicalReport,
  DateTime Function()? now,
}) async {
  if (!await canonicalReport.exists()) return;
  final existingContent = await canonicalReport.readAsString();
  if (existingContent.trim().isEmpty) return;

  final buildLabel = build.toString();
  final timestamp = _archiveTimestamp((now ?? DateTime.now)());
  var sequence = 1;
  File archive;
  do {
    archive = File(path.join(
      reportsDirectory.path,
      'BUILD_${buildLabel}_COMPLETION_REPORT_ARCHIVE_${timestamp}_${sequence.toString().padLeft(3, '0')}.md',
    ));
    sequence++;
  } while (await archive.exists());

  await canonicalReport.copy(archive.path);
  await _trimArchivesForBuild(reportsDirectory, buildLabel);
}

Future<void> _trimArchivesForBuild(
  Directory reportsDirectory,
  String buildLabel,
) async {
  final archivePattern = RegExp(
    '^BUILD_${RegExp.escape(buildLabel)}_COMPLETION_REPORT_ARCHIVE_\\d{8}_\\d{6}_\\d{3}_\\d{3}\\.md\$',
  );
  final archives = <File>[];
  await for (final entry in reportsDirectory.list(followLinks: false)) {
    if (entry is File && archivePattern.hasMatch(path.basename(entry.path))) {
      archives.add(entry);
    }
  }
  archives.sort((left, right) =>
      path.basename(left.path).compareTo(path.basename(right.path)));
  while (archives.length > buildCompletionReportArchiveLimit) {
    await archives.removeAt(0).delete();
  }
}

String _archiveTimestamp(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  String three(int number) => number.toString().padLeft(3, '0');
  return '${value.year.toString().padLeft(4, '0')}${two(value.month)}${two(value.day)}_${two(value.hour)}${two(value.minute)}${two(value.second)}_${three(value.millisecond)}';
}
