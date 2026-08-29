import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX262 historical FIX252 fixture contains Windows transition files', () {
    final source =
        File('test/fix252_final_transition_apply_engine_test.dart')
            .readAsStringSync();
    expect(source, contains("'windows/runner/main.cpp'"));
    expect(source, contains("'windows/runner/Runner.rc'"));
    expect(source, contains('STAVBY PRO DEV'));
  });

  test('FIX262 stale FIX256 identity contract follows current canonical identity', () {
    final source =
        File('test/fix256_stale_regression_contracts_update_test.dart')
            .readAsStringSync();
    expect(source, contains('RC1 DEV001 FIX267'));
    expect(source, isNot(contains("contains('RC1 DEV001 FIX254')")));
  });

  test('FIX263 canonical Release Manager identity is current', () {
    final source = File('lib/app/app_version.dart').readAsStringSync();
    expect(source, contains("RC1 DEV001 FIX267"));
  });
}
