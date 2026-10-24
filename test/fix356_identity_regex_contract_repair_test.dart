import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX356 FIX353 accepts any numeric FIX in DEV015', () {
    final source=File('test/fix353_historical_identity_contract_repair_test.dart').readAsStringSync();
    expect(source, contains('RC1 DEV015 FIX'));
  });

  test('FIX356 FIX354 rejects only stale exact FIX352 pin', () {
    final source=File('test/fix354_fix352_identity_contract_refresh_test.dart').readAsStringSync();
    expect(source, contains('RC1 DEV015 FIX'));
    expect(source, isNot(contains("isNot(contains('RC1 DEV015 FIX'))")));
  });

  test('FIX356 canonical identity remains Build333 DEV015', () {
    final identity=File('lib/app/app_version.dart').readAsStringSync();
    expect(identity, contains('static const int build = 333;'));
    expect(identity, matches(RegExp(r"static const String stage = 'RC1 DEV015 FIX\d+';")));
  });
}
