import 'dart:convert';
import 'dart:io';

import 'execution_history_entry.dart';
import 'pipeline_execution_summary.dart';

class ExecutionHistoryService {
  const ExecutionHistoryService();

  static const int maximumEntries = 100;

  File _file(String projectPath) => File(
        '$projectPath${Platform.pathSeparator}.release_manager'
        '${Platform.pathSeparator}execution_history.json',
      );

  Future<List<ExecutionHistoryEntry>> load(String projectPath) async {
    final file = _file(projectPath);
    if (!await file.exists()) return const <ExecutionHistoryEntry>[];
    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return const <ExecutionHistoryEntry>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return const <ExecutionHistoryEntry>[];
      final entries = <ExecutionHistoryEntry>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          entries.add(
            ExecutionHistoryEntry.fromJson(
              Map<String, Object?>.from(item),
            ),
          );
        } catch (_) {
          // One damaged entry must not make the entire history unreadable.
        }
      }
      entries.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return entries;
    } on FileSystemException {
      return const <ExecutionHistoryEntry>[];
    } on FormatException {
      return const <ExecutionHistoryEntry>[];
    }
  }

  Future<List<ExecutionHistoryEntry>> add(
    PipelineExecutionSummary summary,
  ) async {
    final entries = await load(summary.projectPath);
    final entry = ExecutionHistoryEntry(
      runId: summary.runId,
      projectName: summary.projectName,
      projectPath: summary.projectPath,
      pipelineName: summary.pipelineName,
      startedAt: summary.startedAt,
      finishedAt: summary.finishedAt,
      succeededCount: summary.succeededCount,
      skippedCount: summary.skippedCount,
      failedCount: summary.failedCount,
      cancelledCount: summary.cancelledCount,
    );
    final updated = <ExecutionHistoryEntry>[
      entry,
      ...entries.where((item) => item.runId != entry.runId),
    ].take(maximumEntries).toList(growable: false);

    final file = _file(summary.projectPath);
    await file.parent.create(recursive: true);
    final temporaryFile = File('${file.path}.tmp');
    final json = const JsonEncoder.withIndent('  ').convert(
      updated.map((item) => item.toJson()).toList(growable: false),
    );
    await temporaryFile.writeAsString(json, flush: true);
    if (await file.exists()) await file.delete();
    await temporaryFile.rename(file.path);
    return updated;
  }
}
