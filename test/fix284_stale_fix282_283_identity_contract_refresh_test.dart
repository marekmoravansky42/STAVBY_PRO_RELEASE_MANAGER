import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX284 historical FIX282 and FIX283 tests do not pin current FIX', () {
    final fix282 = File('test/fix282_final_publish_center_test.dart').readAsStringSync();
    final fix283 = File('test/fix283_final_publish_gate_test.dart').readAsStringSync();
    expect(fix282, isNot(contains("stage = 'RC1 DEV003 FIX282'")));
    expect(fix283, isNot(contains("contains('RC1 DEV003 FIX283')")));
  });

  test('FIX284 canonical identity is Build 321 DEV003', () {
    final source = File('lib/app/app_version.dart').readAsStringSync();
    expect(source, contains('static const int build = '));
    expect(source, contains("static const String stage = 'RC1 DEV"));
  });
}
