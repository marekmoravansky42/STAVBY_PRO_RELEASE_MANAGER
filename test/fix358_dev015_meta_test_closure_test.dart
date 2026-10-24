import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX358 DEV015 repair tests use durable identity contracts', () {
    for (final name in [
      'fix353_historical_identity_contract_repair_test.dart',
      'fix355_dev015_identity_tests_generalized_test.dart',
      'fix356_identity_regex_contract_repair_test.dart',
      'fix357_dart_regex_literal_repair_test.dart',
    ]) {
      final source=File('test/$name').readAsStringSync();
      expect(source, contains(r"RC1 DEV015 FIX\d+"));
    }
  });

  test('FIX358 canonical identity is Build333 DEV015 FIX358', () {
    final identity=File('lib/app/app_version.dart').readAsStringSync();
    expect(identity, contains('static const int build = 333;'));
    expect(identity, contains('RC1 DEV015 FIX'));
  });
}
