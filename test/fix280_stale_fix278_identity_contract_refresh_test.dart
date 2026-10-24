import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX280 historical FIX278 test no longer pins an exact FIX', () {
    final source = File('test/fix278_ai_history_compile_order_test.dart').readAsStringSync();
    expect(source, isNot(contains("stage = 'RC1 DEV002 FIX278'")));
    expect(source, contains("stage = 'RC1 DEV"));
  });

  test('FIX280 canonical badge is current', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, contains("static const int build = "));
    expect(version, contains("static const String stage = 'RC1 DEV"));
  });
}
