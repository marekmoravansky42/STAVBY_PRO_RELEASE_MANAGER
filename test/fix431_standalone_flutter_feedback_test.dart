import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX431 standalone Flutter steps show progress and block concurrent actions', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf('Future<bool> _runWorkspaceFlutterStep(');
    final end = source.indexOf('Future<int> _cleanupLegacyUnpackedExportDirectories', start);

    expect(start, greaterThanOrEqualTo(0));
    final runner = source.substring(start, end);
    expect(runner, contains('bool showStandaloneFeedback = false'));
    expect(runner, contains('_busy = true'));
    expect(runner, contains('_startFlutterStepProgress(label)'));
    expect(runner, contains('_finishFlutterStepProgress(success: success)'));
    expect(runner, contains('_busy = false'));
    expect(source, contains('showStandaloneFeedback: true'));
  });
}
