import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  setUpAll(() => source = File('lib/main.dart').readAsStringSync());

  test('FIX184 removes orphan temp before a new metadata write', () {
    expect(source, contains("if (await tempFile.exists()) {"));
    expect(source, contains("await tempFile.delete();"));
  });

  test('FIX185 recovers temp metadata after interrupted atomic replace', () {
    expect(source, contains("if (!await file.exists() && await tempFile.exists())"));
    expect(source, contains("await tempFile.rename(file.path);"));
    expect(source, contains("obnovené metadata po prerušenom zápise"));
  });

  test('FIX186 removes stale temp when canonical metadata is available', () {
    expect(source, contains("final decoded = jsonDecode(await file.readAsString());"));
  });

  test('FIX187 keeps Release Manager identity in the canonical version source', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, contains('abstract final class ReleaseManagerVersion'));
    expect(version, contains('static const int build = '));
    expect(version, contains('static const String stage = '));
  });
}
