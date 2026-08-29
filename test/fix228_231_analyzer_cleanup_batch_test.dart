import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  setUpAll(() => source = File('lib/main.dart').readAsStringSync());

  test('FIX228-230 removes redundant Distribution Center non-null assertions', () {
    expect(source, isNot(contains('_selectedDistributionRelease!')));
    expect(source, isNot(contains('_distributionWindowsExecutable!')));
    expect(source, isNot(contains('_distributionAndroidApk!')));
  });

  test('FIX228-231 keeps identity in the canonical version source', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, contains('abstract final class ReleaseManagerVersion'));
    expect(version, contains('static const int build = '));
    expect(version, contains('static const String stage = '));
  });
}
