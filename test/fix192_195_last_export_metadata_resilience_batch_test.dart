import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  setUpAll(() => source = File('lib/main.dart').readAsStringSync());

  test('FIX192 legacy metadata defaults to schema 1', () {
    expect(source, contains("decoded['schemaVersion'] is int ? decoded['schemaVersion'] as int : 1"));
  });

  test('FIX193 non-object metadata is rejected', () {
    expect(source, contains("last_export.json root must be a JSON object"));
  });

  test('FIX194 recovered temp metadata requires existing ZIP', () {
    expect(source, contains("final normalizedTempZipPath ="));
    expect(source, contains("await File(normalizedTempZipPath).exists()"));
  });

  test('FIX195 invalid temp metadata cleanup is explicit', () {
    expect(source, contains("neobsahovali platný existujúci ZIP"));
  });

  test('FIX192-195 keeps identity in the canonical version source', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, contains('abstract final class ReleaseManagerVersion'));
    expect(version, contains('static const int build = '));
    expect(version, contains('static const String stage = '));
  });
}
