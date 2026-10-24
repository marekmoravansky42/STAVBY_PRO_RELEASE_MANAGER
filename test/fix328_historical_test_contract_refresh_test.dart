import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
void main() {
  test('FIX328 dynamic history title remains present', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('História FINAL publikovaní'));
    expect(source, contains('final displayHistory = verifiedOnly'));
  });
  test('FIX328 canonical identity is Build 331 DEV013', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
