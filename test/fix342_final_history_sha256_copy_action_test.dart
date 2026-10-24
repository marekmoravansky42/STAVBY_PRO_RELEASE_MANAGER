import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX342 FINAL history offers direct SHA-256 copy action', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('onPressed: apkSha256.isEmpty'));
    expect(source, contains('Clipboard.setData('));
    expect(source, contains(RegExp(r'text:\s*apkSha256')));
    expect(source, contains("'SHA-256'"));
    expect(source, contains('SHA-256 bol skopírovaný do schránky.'));
  });

  test('FIX342 canonical identity remains Build 331 DEV013', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version,
        matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
