import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX281 historical FIX278-FIX280 tests do not pin current FIX number', () {
    for (final name in <String>[
      'test/fix278_ai_history_compile_order_test.dart',
      'test/fix279_release_notes_history_proposal_test.dart',
      'test/fix280_stale_fix278_identity_contract_refresh_test.dart',
    ]) {
      final source = File(name).readAsStringSync();
      expect(source, isNot(contains("static const String stage = 'RC1 DEV002 FIX278';")));
      expect(source, isNot(contains("contains('RC1 DEV002 FIX279')")));
      expect(source, contains('RC1 DEV'));
    }
  });

  test('FIX281 canonical badge is current', () {
    final source = File('lib/app/app_version.dart').readAsStringSync();
    expect(source, contains("static const int build = "));
    expect(source, contains("static const String stage = 'RC1 DEV"));
  });
}
