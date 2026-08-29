import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('obsolete dashboard and analyze state stays removed', () {
    final source = File('lib/main.dart').readAsStringSync();
    for (final symbol in <String>[
      '_lastReleaseDistributionAt',
      '_oneClickBuildCompletedSteps',
      '_lastAnalyzeWarnings',
      '_lastAnalyzeInfos',
      '_lastAnalyzeStatus',
      'Widget statusPill(',
      'final sections = <({',
    ]) {
      expect(source, isNot(contains(symbol)));
    }
  });
}
