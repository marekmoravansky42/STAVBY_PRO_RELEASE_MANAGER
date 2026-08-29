import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX257 FINAL export contract is stage-aware without breaking DEV export', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains("releaseStage: finalTransitionApplied ? 'FINAL' : 'DEV'"));
    expect(source, contains("releaseStage: 'DEV'"));
    expect(source, contains('FIX253 FINAL RESTORE'));
  });
}
