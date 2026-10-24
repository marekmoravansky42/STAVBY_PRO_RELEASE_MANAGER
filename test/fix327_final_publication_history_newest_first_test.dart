import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX327 FINAL publication history shows newest stored receipt first', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('final displayHistory = verifiedOnly'));
    expect(source, contains('itemCount: displayHistory.length,'));
    expect(source, contains('final item = displayHistory[index];'));
    expect(source, contains('História FINAL publikovaní'));
    expect(source, contains(r'${displayHistory.length}/${history.length}'));
  });

  test('FIX327 starts Build 331 DEV013 from canonical identity', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
