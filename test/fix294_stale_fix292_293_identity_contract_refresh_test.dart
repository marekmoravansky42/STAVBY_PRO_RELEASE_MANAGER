import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX294 historical FIX292 and FIX293 identity tests do not pin exact FIX', () {
    final fix292 = File('test/fix292_stale_fix289_290_identity_contract_refresh_test.dart').readAsStringSync();
    final fix293 = File('test/fix293_stale_fix291_identity_contract_refresh_test.dart').readAsStringSync();
    expect(fix292, isNot(contains("RC1 DEV004 FIX292';")));
    expect(fix293, isNot(contains("RC1 DEV004 FIX293';")));
  });

  test('FIX294 canonical identity contract remains dynamic', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
  });
}
