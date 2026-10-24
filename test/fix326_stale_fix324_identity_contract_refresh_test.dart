import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX326 recent repair tests do not pin the next exact FIX', () {
    final fix324 = File(
      'test/fix324_stale_fix322_identity_contract_refresh_test.dart',
    ).readAsStringSync();
    final fix325 = File(
      'test/fix325_stale_fix323_identity_contract_refresh_test.dart',
    ).readAsStringSync();
    final version = File('lib/app/app_version.dart').readAsStringSync();

    expect(fix324, isNot(contains("stage = 'RC1 DEV012 FIX324'")));
    expect(fix325, isNot(contains("stage = 'RC1 DEV012 FIX325'")));
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
  });
}
