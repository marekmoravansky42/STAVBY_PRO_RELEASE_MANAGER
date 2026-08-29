import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  setUpAll(() => source = File('lib/main.dart').readAsStringSync());

  test('FIX196 persists absolute export ZIP path', () {
    expect(source, contains("'zipPath': File(zipPath).absolute.path"));
  });

  test('FIX197 normalizes recovered temporary ZIP path', () {
    expect(source, contains("final normalizedTempZipPath ="));
    expect(source, contains("File(normalizedTempZipPath).exists()"));
  });

  test('FIX198 normalizes restored canonical ZIP path', () {
    expect(source, contains("final normalizedSavedPath ="));
    expect(source, contains("? normalizedSavedPath"));
  });

  test('FIX199 removes stale metadata when ZIP disappeared', () {
    expect(source, contains("neaktuálne metadata boli odstránené"));
  });

  test('FIX196-199 keeps identity in the canonical version source', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, contains('abstract final class ReleaseManagerVersion'));
    expect(version, contains('static const int build = '));
    expect(version, contains('static const String stage = '));
  });
}
