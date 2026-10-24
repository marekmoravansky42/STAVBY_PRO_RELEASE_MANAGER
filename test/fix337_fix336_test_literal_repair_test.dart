import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX337 FIX336 SHA source assertion is a raw literal', () {
    final source = File('test/fix336_final_history_apk_details_test.dart').readAsStringSync();
    expect(source, contains(r'''contains(r"'SHA-256: $apkSha256'")'''));
    expect(source, isNot(contains('== false')));
  });

  test('FIX337 production APK details remain intact', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains("final apkSha256 = (item['apkSha256'] as String?)?.trim() ?? '';"));
    expect(source, contains("if (apkSha256.isNotEmpty)"));
    expect(source, contains(r"'SHA-256: $apkSha256'"));
  });

  test('FIX337 canonical identity remains Build 331 DEV013', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
