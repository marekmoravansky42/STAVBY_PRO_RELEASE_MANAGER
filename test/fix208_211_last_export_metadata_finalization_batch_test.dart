import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  setUpAll(() => source = File('lib/main.dart').readAsStringSync());

  test('FIX208 persists metadata timestamp in UTC', () {
    expect(source, contains("DateTime.now().toUtc().toIso8601String()"));
  });

  test('FIX209 unsupported future schema removes stale temp metadata', () {
    expect(source, contains("if (schemaVersion > 1)"));
    expect(source, contains("if (await tempFile.exists())"));
  });

  test('FIX210 normalized restored path is explicitly logged', () {
    expect(source, contains("cesta bola normalizovaná na"));
  });

  test('FIX211 successful metadata persistence logs canonical path', () {
    expect(source, contains("Posledný export ZIP metadata uložené"));
    expect(source, contains("final normalizedZipPath = File(zipPath).absolute.path"));
  });

  test('FIX208-211 keeps identity in the canonical version source', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, contains('abstract final class ReleaseManagerVersion'));
    expect(version, contains('static const int build = '));
    expect(version, contains('static const String stage = '));
  });
}
