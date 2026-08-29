import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  setUpAll(() => source = File('lib/main.dart').readAsStringSync());

  test('FIX212 persists explicit metadata kind', () {
    expect(source, contains("'kind': 'lastVerifiedExportZip'"));
  });

  test('FIX213 validates canonical metadata kind', () {
    expect(source, contains("final metadataKind = decoded['kind']?.toString().trim()"));
    expect(source, contains("Neplatný typ last_export.json"));
  });

  test('FIX214 validates recovered temporary metadata kind', () {
    expect(source, contains("final tempKind ="));
    expect(source, contains("Neplatný typ dočasných last_export metadata"));
  });

  test('FIX215 restored target must be a file', () {
    expect(source, contains("FileSystemEntity.typeSync(normalizedSavedPath)"));
    expect(source, contains("FileSystemEntityType.file"));
  });

  test('FIX212-215 keeps identity in the canonical version source', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, contains('abstract final class ReleaseManagerVersion'));
    expect(version, contains('static const int build = '));
    expect(version, contains('static const String stage = '));
  });
}
