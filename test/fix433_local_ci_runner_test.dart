import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/core/release_pipeline/default_templates.dart';
import 'package:stavby_pro_release_manager/core/release_pipeline/pipeline_storage.dart';
import 'package:stavby_pro_release_manager/core/release_pipeline/pipeline_step.dart';
import 'package:stavby_pro_release_manager/core/release_pipeline/pipeline_step_execution.dart';
import 'package:stavby_pro_release_manager/core/release_pipeline/pipeline_template.dart';
import 'package:stavby_pro_release_manager/features/release_pipeline_designer/release_pipeline_designer_controller.dart';
import 'package:stavby_pro_release_manager/features/release_pipeline_designer/release_pipeline_execution_controller.dart';

void main() {
  test('FIX433 provides four local CI profiles with the expected commands', () {
    expect(
      DefaultPipelineTemplates.ciQuickCheck.steps.map((step) => step.action),
      <String>['flutter_analyze', 'flutter_test'],
    );
    expect(
      DefaultPipelineTemplates.windowsRelease.steps.map((step) => step.action),
      containsAllInOrder(<String>[
        'flutter_clean',
        'flutter_pub_get',
        'flutter_analyze',
        'flutter_test',
        'windows_build',
      ]),
    );
    expect(
      DefaultPipelineTemplates.androidRelease.steps.map((step) => step.action),
      containsAllInOrder(<String>[
        'flutter_clean',
        'flutter_pub_get',
        'flutter_analyze',
        'flutter_test',
        'android_apk',
        'android_aab',
      ]),
    );
    expect(
      DefaultPipelineTemplates.fullRelease.steps.map((step) => step.action),
      containsAllInOrder(
          <String>['windows_build', 'android_apk', 'android_aab']),
    );
  });

  test('FIX433 adds the local CI profiles to an existing designer setup',
      () async {
    final temporaryDirectory =
        await Directory.systemTemp.createTemp('fix433_ci_runner_');
    addTearDown(() => temporaryDirectory.delete(recursive: true));
    final storage = PipelineStorage(
      file: File('${temporaryDirectory.path}/pipelines.json'),
    );
    await storage.save(const <PipelineTemplate>[
      PipelineTemplate(
        id: 'custom',
        name: 'Môj profil',
        steps: <PipelineStep>[
          PipelineStep(id: 'check', title: 'Kontrola', action: 'flutter_test'),
        ],
      ),
    ]);

    final controller = ReleasePipelineDesignerController(storage: storage);
    await controller.load();

    expect(controller.templateById('custom'), isNotNull);
    expect(controller.templateById('ci_quick_check'), isNotNull);
    expect(controller.templateById('full_release'), isNotNull);
    expect(controller.templateById('windows_release'), isNotNull);
    expect(controller.templateById('android_release'), isNotNull);
  });

  test('FIX435 keeps CI analyze successful when it has no errors', () {
    const warningsAndInfos = <String>[
      'warning - Redundant assertion - lib/main.dart:1:1',
      '  info - Add braces - lib/main.dart:2:1',
    ];

    expect(
      ReleasePipelineExecutionController.acceptsAnalyzeResult(
        exitCode: 1,
        output: warningsAndInfos,
      ),
      isTrue,
    );
    expect(
      ReleasePipelineExecutionController.acceptsAnalyzeResult(
        exitCode: 1,
        output: const <String>['error - Undefined name - lib/main.dart:3:1'],
      ),
      isFalse,
    );
  });

  test('FIX436 does not show a false error for a successful test log', () {
    const step =
        PipelineStep(id: 'test', title: 'Flutter test', action: 'flutter_test');
    const succeeded = PipelineStepExecution(
      step: step,
      status: PipelineExecutionStatus.succeeded,
      log: <String>[
        'FIX191 corrupt canonical metadata is removed after failed load',
      ],
    );
    const failed = PipelineStepExecution(
      step: step,
      status: PipelineExecutionStatus.failed,
      log: <String>['error - Test failed'],
    );

    expect(succeeded.errorCount, 0);
    expect(succeeded.firstErrorLine, isNull);
    expect(failed.errorCount, 1);
    expect(failed.firstErrorLine, 'error - Test failed');
  });
}
