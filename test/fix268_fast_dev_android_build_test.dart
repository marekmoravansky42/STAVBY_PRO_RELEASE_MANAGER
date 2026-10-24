import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX268 FAST DEV BUILD includes Android APK for Android projects', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(
      source,
      contains('if (androidSupported)'),
    );
    expect(
      source,
      isNot(contains('if (!fastMode && androidSupported)')),
    );
    expect(source, contains("'build', 'apk', '--release'"));
    expect(
      source,
      contains('Windows Release a Android APK sa vytvoria z rovnakého aktuálneho buildu.'),
    );
  });
}
