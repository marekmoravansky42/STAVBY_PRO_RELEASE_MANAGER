import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX269 current identity follows current canonical build and FIX', () {
    final source = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final versionMatch = RegExp(r'^version:\s*[^+\s]+\+(\d+)\s*$', multiLine: true).firstMatch(pubspec);
    expect(versionMatch, isNotNull);
    final expectedBuild = versionMatch!.group(1)!;
    expect(source, contains('static const int build = $expectedBuild;'));
    expect(source, contains("RC1 DEV"));
  });

  test('FIX269 FAST and FULL Android build share Android support gate', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains("if (androidSupported)"));
    expect(source, contains("['build', 'apk', '--release']"));
    expect(source, isNot(contains("if (!fastMode && androidSupported)")));
  });
}
