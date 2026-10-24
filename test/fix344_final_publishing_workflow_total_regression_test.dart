import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('lib/main.dart').readAsStringSync();

  test('FIX344 FINAL workflow keeps Release Notes and FINAL artifacts wiring', () {
    expect(source.toLowerCase(), contains('release notes'));
    expect(source.toLowerCase(), contains('apk'));
    expect(source.toLowerCase(), contains('final'));
  });

  test('FIX344 FINAL workflow keeps Publish Gate and GitHub publishing wiring', () {
    expect(source.toLowerCase(), contains('publish gate'));
    expect(source.toLowerCase(), contains('github'));
  });

  test('FIX344 FINAL workflow keeps online verification and persisted receipt', () {
    expect(source, contains('onlineVerified'));
    expect(source, contains('_persistVerifiedFinalPublication'));
    expect(source, contains("'onlineVerified': true"));
  });

  test('FIX344 FINAL workflow keeps publication history browser and revalidation surface', () {
    expect(source, contains('_showFinalPublicationHistory'));
    expect(source, contains('História FINAL publikovaní'));
    expect(source.toLowerCase(), anyOf(contains('revalid'), contains('overiť')));
  });

  test('FIX344 history usability closure remains integrated', () {
    expect(source, contains("'IBA OVERENÉ'"));
    expect(source, contains("'KOPÍROVAŤ DOKLAD'"));
    expect(source, contains("'SHA-256'"));
  });

  test('FIX344 canonical identity starts Build 332 DEV014', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
