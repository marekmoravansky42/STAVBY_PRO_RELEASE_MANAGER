import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX307 FIX301-FIX304 historical tests do not pin DEV008', () {
    for (final name in <String>[
      'fix301_final_publication_history_test.dart',
      'fix302_final_publication_audit_root_fix_test.dart',
      'fix303_stale_fix300_identity_contract_refresh_test.dart',
      'fix304_fix303_regex_literal_contract_fix_test.dart',
    ]) {
      final source = File('test/$name').readAsStringSync();
      expect(source, isNot(contains("stage = 'RC1 DEV008 FIX")));
      expect(source, contains(r"RC1 DEV\d{3} FIX\d+"));
    }
  });

  test('FIX307 historical identity remains valid after later FIX', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
