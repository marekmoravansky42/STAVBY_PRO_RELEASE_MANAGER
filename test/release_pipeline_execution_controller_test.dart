import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/core/release_pipeline/pipeline_executor.dart';
import 'package:stavby_pro_release_manager/core/release_pipeline/pipeline_step.dart';
import 'package:stavby_pro_release_manager/core/release_pipeline/pipeline_template.dart';

void main() {
  test('executor runs enabled steps in order and skips disabled steps', () async {
    final calls = <String>[];
    final executor = PipelineExecutor(
      actions: <String, PipelineAction>{
        'first': (step) async {
          calls.add(step.action);
          return 'first done';
        },
        'third': (step) async {
          calls.add(step.action);
          return 'third done';
        },
      },
    );
    const template = PipelineTemplate(
      id: 'test',
      name: 'Test',
      steps: <PipelineStep>[
        PipelineStep(id: '1', title: 'First', action: 'first'),
        PipelineStep(id: '2', title: 'Second', action: 'second', enabled: false),
        PipelineStep(id: '3', title: 'Third', action: 'third'),
      ],
    );

    final report = await executor.run(template);

    expect(report.succeeded, isTrue);
    expect(calls, <String>['first', 'third']);
    expect(report.steps[1].status, PipelineExecutionStatus.skipped);
  });
}

// Build 253 DEV002 keeps runtime progress observable through ChangeNotifier.
// Command-level integration remains covered by the existing controller tests.
