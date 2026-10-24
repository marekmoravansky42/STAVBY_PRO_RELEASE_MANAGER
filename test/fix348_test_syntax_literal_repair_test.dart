import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX348 FIX347 regression source keeps safe literal assertions', () {
    final source = File('test/fix347_negative_meta_contract_repair_test.dart').readAsStringSync();
    expect(source, contains("source.contains"));
    expect(source, contains(r'RC1 DEV013 FIX\d+'));
  });

  test('FIX348 canonical identity remains Build 332 DEV014', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
