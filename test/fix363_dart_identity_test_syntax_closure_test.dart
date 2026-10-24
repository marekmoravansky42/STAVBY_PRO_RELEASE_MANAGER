import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX363 repaired DEV015 identity tests keep dynamic contracts', () {
    final fix356 = File('test/fix356_identity_regex_contract_repair_test.dart').readAsStringSync();
    final fix360 = File('test/fix360_fix358_stale_identity_repair_test.dart').readAsStringSync();

    expect(fix356, contains('RC1 DEV015 FIX'));
    expect(fix360, contains('RC1 DEV015 FIX'));
    expect(fix360, isNot(contains('RC1 DEV015 FIX360')));
  });

  test('FIX363 canonical identity stays Build333 DEV015 with numeric FIX', () {
    final identity = File('lib/app/app_version.dart').readAsStringSync();
    expect(identity, contains('static const int build = 333;'));
    expect(identity, matches(RegExp(r"static const String stage = 'RC1 DEV015 FIX\d+';")));
  });
}
