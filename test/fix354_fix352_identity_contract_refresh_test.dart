import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX354 historical FIX352 does not pin exact FIX', () {
    final source=File('test/fix352_test_import_repair_test.dart').readAsStringSync();
    expect(source, contains('RC1 DEV015 FIX'));
    expect(source, isNot(contains('RC1 DEV015 FIX352')));
  });

  test('FIX354 canonical identity remains Build333 DEV015', () {
    final identity=File('lib/app/app_version.dart').readAsStringSync();
    expect(identity, contains('static const int build = 333;'));
    expect(identity, contains("RC1 DEV015 FIX"));
  });
}
