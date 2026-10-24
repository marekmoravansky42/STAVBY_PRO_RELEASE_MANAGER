import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX347 historical meta expectations follow generalized DEV contract', () {
    final fix329 = File('test/fix329_stale_fix327_identity_contract_refresh_test.dart').readAsStringSync();
    final fix331 = File('test/fix331_meta_test_false_positive_repair_test.dart').readAsStringSync();
    expect(fix329, contains(r'RC1 DEV\d{3} FIX\d+'));
    expect(fix331, contains(r'RC1 DEV\d{3} FIX\d+'));
  });

  test('FIX347 FIX346 guard rejects only positive stale DEV013 matcher', () {
    final source = File('test/fix346_dev013_stage_contract_refresh_test.dart').readAsStringSync();
    expect(source, contains('matches(RegExp'));
    expect(source, contains(r'RC1 DEV013 FIX\d+'));
    expect(source, isNot(contains('source.contains("RC1 DEV013 FIX\\\\d+")')));
  });

  test('FIX347 canonical identity remains Build 332 DEV014', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
