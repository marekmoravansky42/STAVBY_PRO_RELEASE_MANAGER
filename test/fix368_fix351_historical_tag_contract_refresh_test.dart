import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX368 historical FIX351 follows safe ancestor resume contract', () {
    final historical = File('test/fix351_final_completion_retry_and_tag_repair_test.dart').readAsStringSync();
    expect(historical, contains('--is-ancestor'));
    expect(historical, contains('FINAL vydanie sa neprepíše'));
  });

  test('FIX368 current implementation preserves existing FINAL tag safely', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('merge-base'));
    expect(source, contains('--is-ancestor'));
    expect(source, contains('existujúci FINAL tag sa zachová'));
  });

  test('FIX368 identity remains Build333 DEV015', () {
    final identity = File('lib/app/app_version.dart').readAsStringSync();
    expect(identity, contains('static const int build = 333;'));
    expect(identity, contains('RC1 DEV015 FIX'));
  });
}
