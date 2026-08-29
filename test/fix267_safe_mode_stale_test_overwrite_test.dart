import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX267 stale FIX265 test file is present and valid source', () {
    final file = File('test/fix265_test_string_escape_fix_test.dart');
    expect(file.existsSync(), isTrue);

    final source = file.readAsStringSync();
    expect(source, contains('FIX265 regression source remains valid Dart'));
    expect(source, isNot(contains("contains(r\"static const String badge")));
  });

  test('FIX267 canonical identity is Build 317 FIX267', () {
    final source = File('lib/app/app_version.dart').readAsStringSync();
    expect(source, contains('static const int build = 317;'));
    expect(source, contains("RC1 DEV001 FIX267"));
  });
}
