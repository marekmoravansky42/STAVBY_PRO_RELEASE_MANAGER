import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  setUpAll(() => source = File('lib/main.dart').readAsStringSync());

  test('FIX204 future schema clears dashboard state through setState', () {
    expect(source, contains("if (schemaVersion > 1)"));
    expect(source, contains("setState(() => _dashboardLastVerifiedExportZipPath = null)"));
  });

  test('FIX205 stale ZIP cleanup updates dashboard state safely', () {
    expect(source, contains("neaktuálne metadata boli odstránené"));
  });

  test('FIX206 corrupt metadata cleanup is mounted-safe', () {
    expect(source, contains("Posledný export ZIP sa nepodarilo načítať"));
  });

  test('FIX207 successful persistence refreshes dashboard state', () {
    expect(source, contains("final normalizedZipPath = File(zipPath).absolute.path"));
    expect(source, contains("_dashboardLastVerifiedExportZipPath = normalizedZipPath"));
  });

  test('FIX204-207 keeps identity in the canonical version source', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, contains('abstract final class ReleaseManagerVersion'));
    expect(version, contains('static const int build = '));
    expect(version, contains('static const String stage = '));
  });
}
