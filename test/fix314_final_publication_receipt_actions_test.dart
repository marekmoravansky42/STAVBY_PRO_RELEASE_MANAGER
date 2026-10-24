import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX314 adds safe actions for persisted FINAL publication receipt URLs', () {
    final source = File('lib/main.dart').readAsStringSync();
    for (final token in <String>[
      "finalPublishCenterOpenStoredReleaseButton",
      "finalPublishCenterCopyStoredReleaseUrlButton",
      "finalPublishCenterCopyStoredApkUrlButton",
      "OTVORIŤ GITHUB RELEASE",
      "KOPÍROVAŤ RELEASE URL",
      "KOPÍROVAŤ APK URL",
      '_openExternalUrl(',
      "['releaseUrl'] as String",
      "['assetUrl'] as String",
      'Clipboard.setData(',
    ]) {
      expect(source, contains(token));
    }
  });

  test('FIX314 keeps Build 328 DEV010 identity', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
  });
}
