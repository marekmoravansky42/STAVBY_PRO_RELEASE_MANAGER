import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX316 completes readable persisted FINAL publication receipt details', () {
    final source = File('lib/main.dart').readAsStringSync();
    for (final token in <String>[
      "Uložený doklad publikovania",
      'Doklad • cesta projektu:',
      'Doklad • publikované:',
      'Doklad • posledná online revalidácia:',
      'Doklad • uložené overenia:',
      "['versionJsonVerified'] == true",
      "['releaseVerified'] == true",
      "['assetVerified'] == true",
      'Doklad • source FINAL tag:',
      'Doklad • GitHub Release tag:',
      'Doklad • SHA-256:',
      'Doklad • Release URL:',
      'Doklad • APK URL:',
    ]) {
      expect(source, contains(token));
    }
  });

  test('FIX316 keeps stored receipt evidence separate from live online state', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains(r"Aktuálny online stav: ${_lastPublicationVerification?.success == true ? 'OVERENÉ' : 'NEOVERENÉ'}"));
    expect(source, contains('Doklad • uložené overenia:'));
  });

  test('FIX316 identity is Build 329 DEV011', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
