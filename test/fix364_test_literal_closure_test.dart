import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX364 repaired historical tests remain future FIX compatible', () {
    for (final name in <String>[
      'fix356_identity_regex_contract_repair_test.dart',
      'fix360_fix358_stale_identity_repair_test.dart',
      'fix363_dart_identity_test_syntax_closure_test.dart',
    ]) {
      final source = File('test/$name').readAsStringSync();
      expect(source, contains('RC1 DEV015 FIX'), reason: name);
    }
  });

  test('FIX364 identity remains Build333 DEV015 without exact self pin', () {
    final identity = File('lib/app/app_version.dart').readAsStringSync();
    expect(identity, contains('static const int build = 333;'));
    expect(identity, contains('RC1 DEV015 FIX'));
  });
}
