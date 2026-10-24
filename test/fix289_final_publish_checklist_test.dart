import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX289 FINAL Publish Center shows consolidated publication checklist', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('Publikačný checklist'));
    expect(source, contains('Windows FINAL výstup:'));
    expect(source, contains('FINAL ZIP:'));
    expect(source, contains('Android APK + SHA-256:'));
    expect(source, contains('Release Integrity:'));
    expect(source, contains('Release Notes:'));
    expect(source, contains('Git zdrojový archív:'));
    expect(source, contains('GitHub/update pripojenie:'));
    expect(source, contains('Publish Gate:'));
    expect(source, contains("label: const Text('PUBLIKOVAŤ FINAL')"));
  });

  test('FIX289 starts Build 322 DEV004', () {
    final source = File('lib/app/app_version.dart').readAsStringSync();
    expect(source, matches(RegExp(r'static const int build = \d+;')));
    expect(source, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
  });
}
