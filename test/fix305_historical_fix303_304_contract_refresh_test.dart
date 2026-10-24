import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX305 historical FIX303 and FIX304 contracts allow later FIX in DEV008', () {
    final fix303 = File('test/fix303_stale_fix300_identity_contract_refresh_test.dart').readAsStringSync();
    final fix304 = File('test/fix304_fix303_regex_literal_contract_fix_test.dart').readAsStringSync();
    expect(fix303, isNot(contains("stage = 'RC1 DEV008 FIX303'")));
    expect(fix304, isNot(contains("stage = 'RC1 DEV008 FIX304'")));
  });

  test('FIX305 canonical identity remains valid after later builds', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
  });
}
