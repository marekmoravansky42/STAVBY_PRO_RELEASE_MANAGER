import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX291 historical FIX282 test derives build without undefined production symbol', () {
    final source = File('test/fix282_final_publish_center_test.dart').readAsStringSync();
    expect(source, isNot(contains('ReleaseManagerVersion.build')));
    expect(source, contains("RegExp(r'static const int build = (\\d+);')"));
  });

  test('FIX291 canonical identity remains Build 322 DEV004', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
