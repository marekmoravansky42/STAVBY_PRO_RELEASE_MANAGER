import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX256 preserves dynamic release stage for controlled FINAL export', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains('releaseStage'));
    expect(
      source,
      anyOf(
        contains("releaseStage: releaseStage"),
        contains("releaseStage: finalTransitionApplied ? 'FINAL' : 'DEV'"),
      ),
    );
  });

  test('FIX256 production identity follows current canonical FIX267', () {
    final versionSource = File('lib/app/app_version.dart').readAsStringSync();
    expect(versionSource, contains('RC1 DEV001 FIX267'));
  });
}
