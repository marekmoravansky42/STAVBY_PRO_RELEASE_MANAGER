import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX313 shows enriched persisted FINAL publication receipt details', () {
    final source = File('lib/main.dart').readAsStringSync();
    for (final token in <String>[
      'Doklad • projekt:',
      'Doklad • verzia/build:',
      'Doklad • source FINAL tag:',
      'Doklad • GitHub Release tag:',
      'Doklad • APK:',
      'Doklad • SHA-256:',
      'Doklad • Release URL:',
      'Doklad • APK URL:',
    ]) {
      expect(source, contains(token));
    }
    expect(source, contains('Aktuálny online stav:'));
    expect(source, contains('OVERIŤ PUBLIKOVANIE'));
  });

  test('FIX313 canonical identity remains Build 328 DEV010', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
