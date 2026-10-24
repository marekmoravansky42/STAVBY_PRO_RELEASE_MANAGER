import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX365 FIX356 follows generalized FIX354 identity contract', () {
    final source = File('test/fix356_identity_regex_contract_repair_test.dart').readAsStringSync();
    expect(source, contains("contains('RC1 DEV015 FIX')"));
  });

  test('FIX365 identity remains Build333 DEV015 and future FIX compatible', () {
    final identity = File('lib/app/app_version.dart').readAsStringSync();
    expect(identity, contains('static const int build = 333;'));
    expect(identity, contains('RC1 DEV015 FIX'));
  });
}
