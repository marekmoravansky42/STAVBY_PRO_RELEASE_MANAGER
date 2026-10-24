import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/services/project_analyzer_service.dart';

void main() {
  test('Project Analyzer finds a visible window and its widget call sites',
      () async {
    final project = await Directory.systemTemp.createTemp('rm_analyzer_');
    addTearDown(() => project.delete(recursive: true));
    final source = File(
      '${project.path}${Platform.pathSeparator}lib${Platform.pathSeparator}features${Platform.pathSeparator}stavby${Platform.pathSeparator}stavba_form.dart',
    );
    await source.parent.create(recursive: true);
    await source.writeAsString('''
class _StavbaFormState {
  Widget newBuildBasicSection(bool narrow) => Column();
  Widget build() {
    final title = 'Upraviť stavbu';
    return newBuildBasicSection(false);
  }
}
''');

    final result = await const ProjectAnalyzerService().analyze(project.path);
    final titleMatches = result.searchSource('Upraviť stavbu');
    expect(titleMatches, hasLength(1));
    expect(
        titleMatches.single.relativeFile, 'features/stavby/stavba_form.dart');
    expect(titleMatches.single.line, 4);
    expect(titleMatches.single.className, '_StavbaFormState');
    expect(result.searchSource('Upravit stavbu'), hasLength(1));

    final widgetMatches = result.searchSource('newBuildBasicSection');
    expect(widgetMatches.map((match) => match.line), <int>[2, 5]);
    expect(result.searchSource('u'), isEmpty);
  });
}
