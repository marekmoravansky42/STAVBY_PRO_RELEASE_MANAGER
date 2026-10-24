import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX331 FIX329 negative historical assertion remains valid', () {
    final source = File(
      'test/fix329_stale_fix327_identity_contract_refresh_test.dart',
    ).readAsStringSync();

    expect(
      source,
      contains(
        'isNot(contains("stage = \'RC1 DEV013 FIX327\';"))',
      ),
    );
    expect(source, contains(r'RC1 DEV\d{3} FIX\d+'));
  });

  test('FIX331 FIX330 guard checks positive pins only', () {
    final source = File(
      'test/fix330_recent_identity_contract_hardening_test.dart',
    ).readAsStringSync();

    expect(source, contains('do not positively pin exact FIX'));
    expect(source, contains('positive `expect(..., contains'));
  });

  test('FIX331 canonical identity remains Build 331 DEV013', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
