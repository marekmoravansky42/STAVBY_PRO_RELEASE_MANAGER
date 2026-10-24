import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX317 closes Build 329 DEV011 FINAL publication receipt detail contract', () {
    final source = File('lib/main.dart').readAsStringSync();
    for (final token in <String>[
      "Uložený doklad publikovania",
      r"Aktuálny online stav: ${_lastPublicationVerification?.success == true ? 'OVERENÉ' : 'NEOVERENÉ'}",
      'Doklad • cesta projektu:',
      'Doklad • publikované:',
      'Doklad • posledná online revalidácia:',
      'Doklad • uložené overenia:',
      'Doklad • source FINAL tag:',
      'Doklad • GitHub Release tag:',
      'Doklad • APK:',
      'Doklad • SHA-256:',
      'Doklad • Release URL:',
      'Doklad • APK URL:',
      'OTVORIŤ GITHUB RELEASE',
      'KOPÍROVAŤ RELEASE URL',
      'KOPÍROVAŤ APK URL',
      'OVERIŤ PUBLIKOVANIE',
    ]) {
      expect(source, contains(token));
    }
  });

  test('FIX317 keeps persisted verification evidence and live verification separate', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains("['versionJsonVerified'] == true"));
    expect(source, contains("['releaseVerified'] == true"));
    expect(source, contains("['assetVerified'] == true"));
    expect(source, contains(r"Aktuálny online stav: ${_lastPublicationVerification?.success == true ? 'OVERENÉ' : 'NEOVERENÉ'}"));
  });

  test('FIX317 canonical identity closes Build 329 DEV011', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
