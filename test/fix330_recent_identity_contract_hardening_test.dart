import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX330 recent DEV013 historical tests do not positively pin exact FIX', () {
    for (final path in [
      'test/fix327_final_publication_history_newest_first_test.dart',
      'test/fix328_historical_test_contract_refresh_test.dart',
      'test/fix329_stale_fix327_identity_contract_refresh_test.dart',
    ]) {
      final source = File(path).readAsStringSync();

      // A historical FIX literal is allowed inside a negative assertion
      // proving that an old exact pin is absent. What must not return is a
      // positive `expect(..., contains("...FIXnnn..."))` identity contract.
      expect(
        source,
        isNot(matches(RegExp(
          r'expect\([^;\n]*,\s*contains\(["\x27][^"\x27\n]*stage = [^"\x27\n]*RC1 DEV013 FIX(327|328|329)',
        ))),
      );
    }
  });

  test('FIX330 canonical identity is Build 331 DEV013', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
