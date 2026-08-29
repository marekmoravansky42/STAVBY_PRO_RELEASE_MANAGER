import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX253 FINAL dialog button enters controlled FULL BUILD preflight', () {
    final source = File('lib/main.dart').readAsStringSync();

    final finalSelection = source.indexOf("if (selected == 'FINAL')");
    final buildCall = source.indexOf(
      'await _runOneClickBuild(fastMode: false);',
      finalSelection,
    );

    expect(finalSelection, greaterThanOrEqualTo(0));
    expect(buildCall, greaterThan(finalSelection));
    expect(source, contains('FIX253 FINAL UI: používateľ vybral FINAL'));
  });

  test('FIX253 restores DEV configuration after FINAL build or failure', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains('finalTransitionApplied = true;'));
    expect(
      source,
      contains('await _restoreReleaseTransitionConfiguration('),
    );
    expect(source, contains('FIX253 FINAL RESTORE VERIFY:'));
    expect(source, contains('workspace pripravený na ďalší DEV build.'));
  });

  test('FIX253 restore uses the pre-apply configuration backup', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains('finalTransitionBackup = transitionBackup;'));
    expect(source, contains('finalTransitionPlan = finalPlan;'));
    expect(source, contains("FIX253 restore: v zálohe chýba"));
  });
}
