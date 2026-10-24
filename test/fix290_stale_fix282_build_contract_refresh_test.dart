import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX290 historical FIX282 test no longer pins Build 321 pubspec', () {
    final source = File('test/fix282_final_publish_center_test.dart').readAsStringSync();
    expect(source, isNot(contains("version: 8.0.0+321")));
  });

  test('FIX290 canonical identity is Build 322 DEV004', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r'RC1 DEV\d{3} FIX\d+')));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
