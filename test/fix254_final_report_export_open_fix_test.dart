import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX254 FINAL build report and export use actual release stage', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains("final buildReleaseStage = finalTransitionApplied ? 'FINAL' : 'DEV';"));
    expect(source, contains("releaseStage: finalTransitionApplied ? 'FINAL' : 'DEV'"));
    expect(source, contains(r"Release stage buildu: $releaseStage"));
    expect(source, contains('DEV → FINAL aplikovaný pred platform buildmi'));
  });

  test('FIX254 dashboard opens concrete successful build report', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('_lastSuccessfulBuildReportPath = buildReportFile.path'));
    expect(source, contains("Process.start('notepad.exe', <String>[_lastSuccessfulBuildReportPath!])"));
  });
}
