import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  setUpAll(() => source = File('lib/main.dart').readAsStringSync());

  test('FIX200 clears stale in-memory export when ZIP disappeared', () {
    expect(source, contains("_dashboardLastVerifiedExportZipPath = null;"));
    expect(source, contains("neaktuálne metadata boli odstránené"));
  });

  test('FIX201 clears in-memory export when canonical metadata is corrupt', () {
    expect(source, contains("Posledný export ZIP sa nepodarilo načítať"));
  });

  test('FIX202 unsupported future schema clears previous in-memory export', () {
    expect(source, contains("if (schemaVersion > 1)"));
    expect(source, contains("metadata používajú novšiu schému"));
  });

  test('FIX203 successful persistence synchronizes canonical in-memory path', () {
    expect(source, contains("final normalizedZipPath = File(zipPath).absolute.path"));
    expect(source, contains("_dashboardLastVerifiedExportZipPath = normalizedZipPath"));
  });

  test('FIX200-203 keeps identity in the canonical version source', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, contains('abstract final class ReleaseManagerVersion'));
    expect(version, contains('static const int build = '));
    expect(version, contains('static const String stage = '));
  });
}
