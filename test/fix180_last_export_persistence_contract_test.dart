import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  setUpAll(() => source = File('lib/main.dart').readAsStringSync());

  test('last verified export path is persisted per workspace', () {
    expect(source, contains("last_export.json"));
    expect(source, contains("'zipPath': File(zipPath).absolute.path"));
    expect(source, contains('_saveLastVerifiedExportZipPath('));
  });

  test('last verified export is restored during Git workspace refresh', () {
    expect(source, contains('await _loadLastVerifiedExportZipPath(workspace);'));
    expect(source, contains('await File(normalizedSavedPath).exists()'));
  });

  test('missing historical ZIP is not shown as valid export', () {
    expect(source, contains('neaktuálne metadata boli odstránené'));
    expect(source, contains('_dashboardLastVerifiedExportZipPath = validPath'));
  });
}
