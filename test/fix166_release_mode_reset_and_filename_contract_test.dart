import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('export filename stage is derived from pubspec version', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf('Future<File> _createOneClickReleaseZip');
    final end = source.indexOf('Future<void> _selectFileInExplorer', start);
    final block = source.substring(start, end);

    expect(block, contains('final version = currentProject.version;'));
    expect(block, contains('final build = currentProject.releaseBuild;'));
    expect(block, contains("lowerVersion.contains('-rc')"));
    expect(block, contains("? 'RC'"));
    expect(block, contains("lowerVersion.contains('-dev')"));
    expect(block, contains("? 'DEV'"));
    expect(block, contains('final stage ='));
    expect(block, contains('normalizedRequestedStage.isEmpty'));
    expect(
      block,
      isNot(contains("final stage = (identity?.stage ?? 'DEV')")),
    );
  });

  test('RC and FINAL reset One Click mode back to DEV', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf(
      'Future<void> _runOneClickReleaseComplete() async',
    );
    final end = source.indexOf('Future<bool> _applyReleaseRecipe', start);
    final block = source.substring(start, end);

    expect(block, contains("if (selected != 'DEV')"));
    expect(block, contains('await _restoreDevelopmentRecipe();'));
    expect(block, contains("_oneClickReleaseMode = 'DEV'"));
    expect(block, contains("saveOneClickReleaseMode('DEV')"));
  });
}
