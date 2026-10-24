import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('lib/main.dart').readAsStringSync();

  test('FIX349 closes total FINAL publishing workflow regression', () {
    expect(source.toLowerCase(), contains('release notes'));
    expect(source.toLowerCase(), contains('publish gate'));
    expect(source.toLowerCase(), contains('github'));
    expect(source, contains('onlineVerified'));
    expect(source, contains('_persistVerifiedFinalPublication'));
    expect(source, contains('_showFinalPublicationHistory'));
  });

  test('FIX349 keeps FINAL history usability actions integrated', () {
    expect(source, contains("'IBA OVERENÉ'"));
    expect(source, contains("'KOPÍROVAŤ DOKLAD'"));
    expect(source, contains("'SHA-256'"));
  });

  test('FIX349 canonical identity remains Build 332 DEV014', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
