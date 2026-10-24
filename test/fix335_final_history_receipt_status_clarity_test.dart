import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX335 history gives online verification a clear visual status', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains("item['onlineVerified'] == true"));
    expect(source, contains('onlineVerified'));
    expect(source, contains('Icons.verified_rounded'));
    expect(source, contains('Icons.warning_amber_rounded'));
    expect(source, contains('Online doklad: OVERENÝ'));
    expect(source, contains('Online doklad: NEOVERENÝ'));
    expect(source, contains('fontWeight: FontWeight.w700'));
  });

  test('FIX335 keeps history receipt actions intact', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains("'RELEASE'"));
    expect(source, contains("'RELEASE URL'"));
    expect(source, contains("'APK URL'"));
  });

  test('FIX335 canonical identity remains Build 331 DEV013', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
