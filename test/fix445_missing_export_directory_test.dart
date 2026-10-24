import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('lib/main.dart').readAsStringSync();

  test('FIX445 retries Windows and Android export path selection safely', () {
    for (final method in <String>[
      '_chooseWindowsReleaseExportDirectory',
      '_chooseAndroidReleaseExportDirectory',
    ]) {
      final start = source.indexOf('Future<void> $method');
      final end = source.indexOf('Future<void>', start + 1);
      final block = source.substring(start, end);
      expect(block, contains('_pickDirectorySafely('));
      expect(block, contains('savedDirectory:'));
    }
    expect(source, contains('opakujem výber bez počiatočného priečinka.'));
  });
}