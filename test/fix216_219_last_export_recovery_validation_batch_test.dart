import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  setUpAll(() => source = File('lib/main.dart').readAsStringSync());

  test('FIX216 temp recovery target must be a file', () {
    expect(source, contains("FileSystemEntity.typeSync(normalizedTempZipPath)"));
  });

  test('FIX217 temp recovery target must have ZIP extension', () {
    expect(source, contains("normalizedTempZipPath.toLowerCase().endsWith('.zip')"));
  });

  test('FIX218 canonical restored target must have ZIP extension', () {
    expect(source, contains("normalizedSavedPath.toLowerCase().endsWith('.zip')"));
  });

  test('FIX219 persistence rejects non-ZIP input path', () {
    expect(source, contains("normalizedInputZipPath.toLowerCase().endsWith('.zip')"));
    expect(source, contains("cesta nemá príponu .zip"));
  });

  test('FIX216-219 keeps identity in the canonical version source', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, contains('abstract final class ReleaseManagerVersion'));
    expect(version, contains('static const int build = '));
    expect(version, contains('static const String stage = '));
  });
}
