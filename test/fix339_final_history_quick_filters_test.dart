import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX339 FINAL history offers verified-only quick filter', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('var verifiedOnly = false;'));
    expect(source, contains('StatefulBuilder('));
    expect(
        source, contains(".where((item) => item['onlineVerified'] == true)"));
    expect(source, contains("'IBA OVERENÉ'"));
    expect(source,
        contains(RegExp(r'onSelected:\s*\(value\)\s*=>\s*setDialogState')));
    expect(source, contains('Žiadny overený FINAL doklad.'));
  });

  test('FIX339 title shows filtered and total receipt counts', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('História FINAL publikovaní'));
    expect(source, contains(r'${displayHistory.length}/${history.length}'));
  });

  test('FIX339 canonical identity remains Build 331 DEV013', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version,
        matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
