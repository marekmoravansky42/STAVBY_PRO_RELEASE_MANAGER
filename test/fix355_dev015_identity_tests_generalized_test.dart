import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX355 recent DEV015 historical tests avoid positive exact prior identity pins', () {
    final files = [
      'fix350_final_publish_center_reentry_test.dart',
      'fix351_final_completion_retry_and_tag_repair_test.dart',
      'fix352_test_import_repair_test.dart',
      'fix353_historical_identity_contract_repair_test.dart',
      'fix354_fix352_identity_contract_refresh_test.dart',
    ];
    final positivePin = RegExp(
      r'''expect\([^\n]*,\s*contains\(['"]RC1 DEV015 FIX\d+['"]\)\s*\)''',
    );
    for (final name in files) {
      final source = File('test/$name').readAsStringSync();
      expect(
        positivePin.hasMatch(source),
        isFalse,
        reason: '$name must not positively pin an exact prior FIX as current identity',
      );
    }
  });

  test('FIX355 canonical identity remains Build333 DEV015', () {
    final identity=File('lib/app/app_version.dart').readAsStringSync();
    expect(identity, contains('static const int build = 333;'));
    expect(identity, matches(RegExp(r"static const String stage = 'RC1 DEV015 FIX\d+';")));
  });
}
