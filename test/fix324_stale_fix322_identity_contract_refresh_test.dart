import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX324 historical FIX322 regression no longer pins exact current FIX', () {
    final historical = File(
      'test/fix322_dialog_parenthesis_syntax_repair_test.dart',
    ).readAsStringSync();
    final version = File('lib/app/app_version.dart').readAsStringSync();

    expect(
      historical,
      isNot(contains(
        'expect(version, contains("static const String stage = \'RC1 DEV012 FIX322\';"));',
      )),
    );
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
  });
}
