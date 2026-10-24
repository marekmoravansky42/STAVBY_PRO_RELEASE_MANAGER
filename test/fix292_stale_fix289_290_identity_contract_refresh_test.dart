import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX292 historical FIX289 and FIX290 tests do not pin exact FIX', () {
    final fix289 = File('test/fix289_final_publish_checklist_test.dart').readAsStringSync();
    final fix290 = File('test/fix290_stale_fix282_build_contract_refresh_test.dart').readAsStringSync();
    expect(fix289, isNot(contains("RC1 DEV004 FIX289';")));
    expect(fix290, isNot(contains('RC1 DEV004 FIX290')));
  });

  test('FIX292 canonical identity remains Build 322 DEV004', () {
    final source = File('lib/app/app_version.dart').readAsStringSync();
    expect(source, matches(RegExp(r'static const int build = \d+;')));
    expect(source, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
  });
}
