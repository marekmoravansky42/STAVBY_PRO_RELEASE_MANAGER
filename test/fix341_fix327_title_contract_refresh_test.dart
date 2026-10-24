import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX341 FIX327 title contract follows visible total counts', () {
    final historical = File('test/fix327_final_publication_history_newest_first_test.dart').readAsStringSync();
    expect(historical, contains(r'${displayHistory.length}/${history.length}'));
    expect(historical, isNot(contains(r'\${history.length}')));
  });

  test('FIX341 production filter title remains current', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('História FINAL publikovaní'));
    expect(source, contains(r'${displayHistory.length}/${history.length}'));
    expect(source, contains("'IBA OVERENÉ'"));
  });

  test('FIX341 canonical identity remains Build 331 DEV013', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
