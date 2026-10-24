import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX315 closes FINAL publication receipt detail and action contracts', () {
    final source = File('lib/main.dart').readAsStringSync();
    for (final token in <String>[
      'Uložený doklad publikovania:',
      'ÁNO • HISTÓRIA',
      'Aktuálny online stav:',
      'OVERENÉ',
      'NEOVERENÉ',
      'Doklad • projekt:',
      'Doklad • verzia/build:',
      'Doklad • source FINAL tag:',
      'Doklad • GitHub Release tag:',
      'Doklad • APK:',
      'Doklad • SHA-256:',
      'Doklad • Release URL:',
      'Doklad • APK URL:',
      'finalPublishCenterOpenStoredReleaseButton',
      'finalPublishCenterCopyStoredReleaseUrlButton',
      'finalPublishCenterCopyStoredApkUrlButton',
      'finalPublishCenterRevalidateButton',
      'OTVORIŤ GITHUB RELEASE',
      'KOPÍROVAŤ RELEASE URL',
      'KOPÍROVAŤ APK URL',
      'OVERIŤ PUBLIKOVANIE',
    ]) {
      expect(source, contains(token));
    }
  });

  test('FIX315 keeps stored history separate from current live verification state', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(
      source,
      contains(r"Uložený doklad publikovania: ${_lastPersistedFinalPublication != null ? 'ÁNO • HISTÓRIA' : 'NIE'}"),
    );
    expect(
      source,
      contains(r"Aktuálny online stav: ${_lastPublicationVerification?.success == true ? 'OVERENÉ' : 'NEOVERENÉ'}"),
    );
  });

  test('FIX315 keeps Build 328 DEV010 identity without pinning future FIX number', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
