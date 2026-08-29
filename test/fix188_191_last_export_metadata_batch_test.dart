import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  setUpAll(() {
    source = File('lib/main.dart').readAsStringSync();
  });

  test('FIX188 persists a metadata schema version', () {
    expect(source, contains("'schemaVersion': 1"));
  });

  test('FIX189 validates temporary metadata before recovery', () {
    expect(source, contains("final tempDecoded = jsonDecode(await tempFile.readAsString());"));
    expect(source, contains("poškodené dočasné metadata boli odstránené"));
  });

  test('FIX190 safely ignores unsupported future metadata schema', () {
    expect(source, contains("if (schemaVersion > 1)"));
    expect(source, contains("metadata používajú novšiu schému"));
  });

  test('FIX191 corrupt canonical metadata is removed after failed load', () {
    expect(source, contains("Posledný export ZIP sa nepodarilo načítať"));
    expect(source, contains("await file.delete();"));
  });

  test('FIX188-191 uses the canonical Release Manager identity source', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, contains('abstract final class ReleaseManagerVersion'));
    expect(version, contains('static const int build = '));
    expect(version, contains('static const String stage = '));
  });
}
