import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/core/release_pipeline/default_templates.dart';
import 'package:stavby_pro_release_manager/core/release_pipeline/pipeline_executor.dart';
import 'package:stavby_pro_release_manager/core/release_pipeline/pipeline_step.dart';
import 'package:stavby_pro_release_manager/core/release_pipeline/pipeline_template.dart';
import 'package:stavby_pro_release_manager/core/release_pipeline/pipeline_validator.dart';

void main() {
  test('pipeline template JSON roundtrip preserves steps', () {
    final restored = PipelineTemplate.fromJson(
      DefaultPipelineTemplates.fullRelease.toJson(),
    );
    expect(restored.id, 'full_release');
    final stepIds = restored.steps.map((step) => step.id).toList();
    expect(stepIds, containsAll(<String>[
      'flutter_clean',
      'flutter_pub_get',
      'flutter_analyze',
      'flutter_test',
      'windows_build',
    ]));
    expect(restored.steps.length, DefaultPipelineTemplates.fullRelease.steps.length);
    expect(restored.isDefault, isTrue);
  });

  test('validator rejects duplicate step identifiers', () {
    const template = PipelineTemplate(
      id: 'duplicate',
      name: 'Duplicate',
      steps: <PipelineStep>[
        PipelineStep(id: 'same', title: 'One', action: 'one'),
        PipelineStep(id: 'same', title: 'Two', action: 'two'),
      ],
    );
    final result = const PipelineValidator().validate(template);
    expect(result.isValid, isFalse);
  });

  test('unsupported platform step is skipped without stopping pipeline', () async {
    const template = PipelineTemplate(
      id: 'platform_skip',
      name: 'Platform skip',
      steps: <PipelineStep>[
        PipelineStep(
          id: 'android',
          title: 'Android',
          action: 'android',
          requiredPlatforms: <String>['android'],
        ),
        PipelineStep(id: 'diagnostics', title: 'Diagnostics', action: 'diagnostics'),
      ],
    );
    final executor = PipelineExecutor(
      actions: <String, PipelineAction>{
        'android': (_) async => 'must not run',
        'diagnostics': (_) async => 'done',
      },
      skipReason: (step) => step.requiredPlatforms.contains('android')
          ? 'Platforma Android nie je podporovaná.'
          : null,
    );

    final report = await executor.run(template);

    expect(report.succeeded, isTrue);
    expect(report.steps.first.status, PipelineExecutionStatus.skipped);
    expect(report.steps.first.message, contains('Android'));
    expect(report.steps.last.status, PipelineExecutionStatus.succeeded);
  });

  test('executor skips remaining steps after failure', () async {
    const template = PipelineTemplate(
      id: 'test',
      name: 'Test',
      steps: <PipelineStep>[
        PipelineStep(id: 'fail', title: 'Fail', action: 'fail'),
        PipelineStep(id: 'next', title: 'Next', action: 'next'),
      ],
    );
    final executor = PipelineExecutor(actions: <String, PipelineAction>{
      'fail': (_) async => throw StateError('failure'),
      'next': (_) async => 'done',
    });
    final report = await executor.run(template);
    expect(report.succeeded, isFalse);
    expect(report.steps.first.status, PipelineExecutionStatus.failed);
    expect(report.steps.last.status, PipelineExecutionStatus.skipped);
  });
}

// FIX002 compatibility is covered by ProjectWorkspace tests and by the
// requiredPlatforms JSON round-trip in PipelineStep.
