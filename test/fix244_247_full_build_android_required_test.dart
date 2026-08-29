import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  setUpAll(() => source = File('lib/main.dart').readAsStringSync());

  test('FIX244 detects Android support before FULL BUILD steps', () {
    expect(source, contains("final androidSupported ="));
    expect(source, contains("Directory(path.join(workspace, 'android')).exists()"));
  });

  test('FIX245 FULL BUILD runs Android APK Release build', () {
    expect(source, contains("if (!fastMode && androidSupported)"));
    expect(source, contains("['build', 'apk', '--release']"));
    expect(source, contains("Android APK Release build"));
  });

  test('FIX246 FULL BUILD export failure is fatal', () {
    expect(source, contains("if (!fastMode) {\n            rethrow;"));
  });

  test('FIX247 FULL BUILD completion reports Android step', () {
    expect(source, contains("androidSupported ? '\\n✔ Android APK Release build' : ''"));
  });

  test('current batch identity is Build 317 FIX267', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, contains('static const int build = 317;'));
    expect(version, contains("RC1 DEV001 FIX267"));
  });
}
