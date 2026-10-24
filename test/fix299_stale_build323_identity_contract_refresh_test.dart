import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX299 historical FIX295 and FIX297 tests do not pin Build 323', () {
    final fix295 = File('test/fix295_final_git_archive_verification_test.dart').readAsStringSync();
    final fix297 = File('test/fix297_historical_publish_gate_contract_refresh_test.dart').readAsStringSync();
    expect(fix295, isNot(contains("static const int build = 323;")));
    expect(fix297, isNot(contains("static const int build = 323;")));
  });
}
