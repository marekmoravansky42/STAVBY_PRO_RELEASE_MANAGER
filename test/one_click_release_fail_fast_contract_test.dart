import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('One Click Release checks FULL BUILD failure before using Android artifact', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf('Future<void> _runOneClickReleaseComplete()');
    final end = source.indexOf('Future<bool> _applyReleaseRecipe', start);
    final block = source.substring(start, end);
    final build = block.indexOf(
      'await _runOneClickBuild(\n'
      '        fastMode: fastDevRelease,\n'
      '        exportReleaseZip: false,\n'
      '        showCompletionDialog: false,\n'
      '      );',
    );
    final failure = block.indexOf('_oneClickBuildFailedLabel != null');
    final android = block.indexOf('Používam Android Release APK vytvorené ');
    expect(build, greaterThanOrEqualTo(0));
    expect(failure, greaterThan(build));
    expect(android, greaterThan(failure));
  });

  test('Android and Windows-only exports keep physical gate before integrity', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf('Future<void> _runOneClickReleaseComplete()');
    final end = source.indexOf('Future<bool> _applyReleaseRecipe', start);
    final block = source.substring(start, end);

    expect(block, contains('finalReleaseZip = combinedReleaseZip;'));
    expect(block, contains('finalReleaseZip = windowsOnlyReleaseZip;'));
    expect(block, contains('!await verifiedReleaseZip.exists()'));
    expect(block, contains('await verifiedReleaseZip.length() <= 0'));
    expect(block, isNot(contains('verifiedReleaseZip == null')));
    expect(
      block.indexOf('ONE CLICK RELEASE EXPORT GATE OK:'),
      lessThan(block.indexOf('Vytváram SHA-256 manifest...')),
    );
  });

  test('combined export uses native recursive copy, not LiteralPath wildcard', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf(
      'Future<File> _createOneClickReleaseZip(',
    );
    final end = source.indexOf('Future<void> _selectFileInExplorer', start);
    final block = source.substring(start, end);
    expect(block, contains('windowsReleaseDirectory.list('));
    expect(block, isNot(contains('Copy-Item -LiteralPath')));
  });
}
