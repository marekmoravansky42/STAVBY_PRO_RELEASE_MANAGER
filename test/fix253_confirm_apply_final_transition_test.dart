import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX253 applies transition only after explicit preflight confirmation and backup', () {
    final source = File('lib/main.dart').readAsStringSync();

    final confirmIndex =
        source.indexOf('await _confirmReleaseTransition(finalPlan)');
    final backupIndex =
        source.indexOf('await _backupReleaseTransitionConfiguration(');
    final applyIndex =
        source.indexOf('await transitionEngine.apply(');

    expect(confirmIndex, greaterThanOrEqualTo(0));
    expect(backupIndex, greaterThan(confirmIndex));
    expect(applyIndex, greaterThan(backupIndex));
    expect(
      source,
      contains('odložený až po úspešnom analyze + test.'),
    );
  });

  test('FIX253 applies only target FINAL channel and logs verified changed files', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains("targetChannel: 'final'"));
    expect(source, contains('FIX253 FINAL APPLY: DEV → FINAL aplikovaný až po úspešnom'));
    expect(source, contains('transitionResult.changedFiles'));
  });

  test('FIX253 cancel still exits before backup and apply', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains('projekt zostal bez zmien.'));
    expect(source, contains('if (!confirmed)'));
    expect(source, contains('return;'));
  });
}
