import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX253 transition engine remains local to FINAL platform-build gate', () {
    final source = File('lib/main.dart').readAsStringSync();

    final gateIndex = source.indexOf('final isPlatformBuildStep =');
    final localEngineIndex = source.indexOf(
      'const ProjectReleaseTransitionEngine();',
      gateIndex,
    );
    final applyIndex = source.indexOf(
      'await transitionEngine.apply(',
      gateIndex,
    );

    expect(gateIndex, greaterThanOrEqualTo(0));
    expect(localEngineIndex, greaterThan(gateIndex));
    expect(applyIndex, greaterThan(localEngineIndex));
    expect(source, isNot(contains('_releaseTransitionEngine.apply(')));
  });

  test('FIX253 FINAL apply remains deferred until DEV analyze and tests pass', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(
      source,
      contains('odložený až po úspešnom analyze + test.'),
    );
    expect(
      source,
      contains('FIX253 FINAL APPLY: DEV → FINAL aplikovaný až po úspešnom'),
    );
  });
}
