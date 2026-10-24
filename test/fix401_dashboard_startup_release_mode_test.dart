import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX401 startup Dashboard selects DEV without touching completion data', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf('Future<void> _loadAppSettings()');
    final end = source.indexOf('\n  Future<void> ', start + 1);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final block = source.substring(start, end);
    expect(block, contains("_oneClickReleaseMode = 'DEV'"));
    expect(block, isNot(contains('_oneClickReleaseMode = settings.oneClickReleaseMode')));
    expect(block, isNot(contains('build_completion_preferences.json')));
  });
}
