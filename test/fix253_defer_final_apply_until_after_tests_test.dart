import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX253 FINAL apply is deferred until after analyze and test', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(
      source,
      contains('FINAL apply pripravený,'),
    );
    expect(
      source,
      contains('odložený až po úspešnom analyze + test.'),
    );

    final loopIndex =
        source.indexOf('for (var index = startIndex; index < steps.length; index++)');
    final applyIndex =
        source.indexOf('await transitionEngine.apply(', loopIndex);
    final platformGateIndex =
        source.indexOf('final isPlatformBuildStep =', loopIndex);

    expect(loopIndex, greaterThanOrEqualTo(0));
    expect(platformGateIndex, greaterThan(loopIndex));
    expect(applyIndex, greaterThan(platformGateIndex));
  });

  test('FIX253 platform builds happen in FINAL but tests still run in DEV', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains("step.args[1] == 'windows' || step.args[1] == 'apk'"));
    expect(
      source,
      contains('FIX253 FINAL APPLY: DEV → FINAL aplikovaný až po úspešnom'),
    );
  });

  test('FIX253 failed DEV tests never trigger FINAL apply', () {
    final source = File('lib/main.dart').readAsStringSync();

    final failureReturn = source.indexOf('if (!ok) {');
    final applyIndex = source.indexOf('await transitionEngine.apply(');

    expect(failureReturn, greaterThanOrEqualTo(0));
    expect(applyIndex, greaterThanOrEqualTo(0));
    expect(source, contains('finalTransitionApplied = true;'));
    expect(
      source,
      contains('if (finalTransitionApplied &&'),
    );
  });
}
