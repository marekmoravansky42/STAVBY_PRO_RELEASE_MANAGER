import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX340 historical history tests accept filtered display history', () {
    for (final path in <String>[
      'test/fix327_final_publication_history_newest_first_test.dart',
      'test/fix328_historical_test_contract_refresh_test.dart',
      'test/fix332_final_history_order_correction_test.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source,
          isNot(contains("contains('final displayHistory = history;')")));
    }
  });

  test('FIX340 production preserves single reverse and verified filter', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains(RegExp(r'\.reversed\s*\.toList\(\)')));
    expect(source, contains('final displayHistory = verifiedOnly'));
    expect(
        source, contains(".where((item) => item['onlineVerified'] == true)"));
    expect(source, isNot(contains('history.reversed.toList(growable: false)')));
  });

  test('FIX340 canonical identity remains Build 331 DEV013', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version,
        matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
