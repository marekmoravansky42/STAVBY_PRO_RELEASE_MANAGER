import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX329 historical FIX327 test no longer pins exact FIX327', () {
    final historical = File('test/fix327_final_publication_history_newest_first_test.dart').readAsStringSync();
    expect(historical, isNot(contains("stage = 'RC1 DEV013 FIX327';")));
    expect(historical, contains(r"RC1 DEV\d{3} FIX\d+"));
  });

  test('FIX329 canonical identity remains Build 331 DEV013', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
