import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/core/release_pipeline/pipeline_storage.dart';
import 'package:stavby_pro_release_manager/features/release_pipeline_designer/release_pipeline_designer_controller.dart';

void main() {
  test('loads defaults, edits order and persists templates', () async {
    final temp = await Directory.systemTemp.createTemp('pipeline_designer_test_');
    addTearDown(() => temp.delete(recursive: true));
    final storage = PipelineStorage(file: File('${temp.path}/pipelines.json'));
    final controller = ReleasePipelineDesignerController(storage: storage);

    await controller.load();
    expect(controller.templates, isNotEmpty);
    expect(
      File('${temp.path}/release_pipeline_state.json').existsSync(),
      isTrue,
      reason: 'load() must await persistence of the selected pipeline ID',
    );
    final selected = controller.selectedTemplate!;
    final firstId = selected.steps.first.id;

    controller.moveStep(firstId, 1);
    expect(controller.selectedTemplate!.steps[1].id, firstId);
    expect(await controller.save(), isTrue);

    final reloaded = ReleasePipelineDesignerController(storage: storage);
    await reloaded.load();
    expect(reloaded.selectedTemplate!.steps[1].id, firstId);
  });
}
