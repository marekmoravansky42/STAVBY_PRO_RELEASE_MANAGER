import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stavby_pro_release_manager/core/release_pipeline/execution_history_service.dart';
import 'package:stavby_pro_release_manager/core/release_pipeline/pipeline_execution_summary.dart';
import 'package:stavby_pro_release_manager/core/release_pipeline/pipeline_step_execution.dart';

void main() {
  const service = ExecutionHistoryService();

  test('damaged history does not prevent loading project', () async {
    final root = await Directory.systemTemp.createTemp('rm_history_bad_');
    addTearDown(() => root.delete(recursive: true));
    final directory = Directory(path.join(root.path, '.release_manager'));
    await directory.create(recursive: true);
    await File(path.join(directory.path, 'execution_history.json'))
        .writeAsString('{not valid json');

    final entries = await service.load(root.path);

    expect(entries, isEmpty);
  });

  test('history is deduplicated, sorted and limited', () async {
    final root = await Directory.systemTemp.createTemp('rm_history_limit_');
    addTearDown(() => root.delete(recursive: true));
    final base = DateTime(2026, 1, 1);

    for (var index = 0; index < 105; index++) {
      final started = base.add(Duration(minutes: index));
      await service.add(PipelineExecutionSummary(
        runId: 'run-$index',
        projectName: 'Sample',
        projectPath: root.path,
        pipelineName: 'Full Release',
        startedAt: started,
        finishedAt: started.add(const Duration(seconds: 1)),
        platformLabels: const <String>['Windows'],
        steps: const <PipelineStepExecution>[],
        pluginIds: const <String>{},
      ));
    }

    final entries = await service.load(root.path);

    expect(entries, hasLength(ExecutionHistoryService.maximumEntries));
    expect(entries.first.runId, 'run-104');
    expect(entries.last.runId, 'run-5');
  });

  test('clearing history removes only this workspace history file', () async {
    final root = await Directory.systemTemp.createTemp('rm_history_clear_');
    final otherRoot =
        await Directory.systemTemp.createTemp('rm_history_other_');
    addTearDown(() => root.delete(recursive: true));
    addTearDown(() => otherRoot.delete(recursive: true));
    final started = DateTime(2026, 9, 14, 18);

    Future<void> addFor(String projectPath, String runId) => service.add(
          PipelineExecutionSummary(
            runId: runId,
            projectName: 'Sample',
            projectPath: projectPath,
            pipelineName: 'Full Release',
            startedAt: started,
            finishedAt: started.add(const Duration(seconds: 1)),
            platformLabels: const <String>['Windows'],
            steps: const <PipelineStepExecution>[],
            pluginIds: const <String>{},
          ),
        );

    await addFor(root.path, 'current-workspace');
    await addFor(otherRoot.path, 'other-workspace');
    await service.clear(root.path);

    expect(await service.load(root.path), isEmpty);
    expect(
        (await service.load(otherRoot.path)).single.runId, 'other-workspace');
  });
}
