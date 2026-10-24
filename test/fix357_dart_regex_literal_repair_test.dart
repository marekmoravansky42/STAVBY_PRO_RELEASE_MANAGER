import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX357 FIX353 regex uses valid Dart raw string literal', () {
    final source = File('test/fix353_historical_identity_contract_repair_test.dart').readAsStringSync();
    expect(source, contains('RegExp(r"static const String stage ='));
    expect(source, contains(r"RC1 DEV015 FIX\d+"));
    expect(source, isNot(contains(r'RegExp(r\"')));
  });

  test('FIX357 canonical identity is Build333 DEV015 FIX357', () {
    final identity = File('lib/app/app_version.dart').readAsStringSync();
    expect(identity, contains('static const int build = 333;'));
    expect(identity, matches(RegExp(r"static const String stage = 'RC1 DEV015 FIX\d+';")));
  });
}
