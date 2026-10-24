import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX312 closes FINAL publication receipt contracts without pinning future FIX', () {
    final source = File('lib/main.dart').readAsStringSync();
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(source, contains('Uložený doklad publikovania:'));
    expect(source, contains('Aktuálny online stav:'));
    expect(source, contains('OVERIŤ PUBLIKOVANIE'));
    expect(source, contains("'apkSha256': _apkSha256"));
    expect(source, contains("'apkSizeBytes': _apkSizeBytes"));
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
  });
}
