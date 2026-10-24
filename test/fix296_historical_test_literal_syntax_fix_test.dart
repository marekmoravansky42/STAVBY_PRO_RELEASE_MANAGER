import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX296 historical identity prefix assertions use valid Dart string literals', () {
    for (final path in [
      'test/fix291_fix282_dynamic_build_contract_compile_fix_test.dart',
      'test/fix292_stale_fix289_290_identity_contract_refresh_test.dart',
      'test/fix293_stale_fix291_identity_contract_refresh_test.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('contains(\"static const String stage = \'RC1 DEV004 FIX\")')));
    }
  });
}
