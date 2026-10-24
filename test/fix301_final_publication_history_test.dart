import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX301 persists online verified FINAL publication and restores it in Publish Center', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains("final_publications.json"));
    expect(source, contains('_persistVerifiedFinalPublication('));
    expect(source, contains('_readPersistedFinalPublication()'));
    expect(source, contains("'onlineVerified': true"));
    expect(source, contains("event: 'FINAL_PUBLICATION_ONLINE_VERIFIED'"));
    expect(source, contains('Uložený doklad publikovania:'));
    expect(source, contains('Aktuálny online stav:'));
  });

  test('FIX301 historical identity remains valid after later DEV/FIX', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
