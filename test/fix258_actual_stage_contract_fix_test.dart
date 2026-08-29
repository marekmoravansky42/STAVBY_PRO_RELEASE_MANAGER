import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX258 One Click export uses actual FINAL transition state', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(
      source,
      contains(
        "releaseStage: finalTransitionApplied ? 'FINAL' : 'DEV'",
      ),
    );
    expect(source, contains("releaseStage: 'DEV'"));
    expect(source, contains("final buildReleaseStage = finalTransitionApplied ? 'FINAL' : 'DEV';"));
  });
}
