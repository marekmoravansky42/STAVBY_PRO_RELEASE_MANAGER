import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX293 historical FIX291 identity does not pin exact FIX', () {
    final source = File('test/fix291_fix282_dynamic_build_contract_compile_fix_test.dart').readAsStringSync();
    expect(source, isNot(contains("RC1 DEV004 FIX291';")));
    expect(source, contains(r'RC1 DEV\d{3} FIX\d+'));
  });

  test('FIX293 canonical identity remains dynamic', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
  });
}
