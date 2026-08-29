import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  setUpAll(() => source = File('lib/main.dart').readAsStringSync());

  test('last export state is cleared before workspace metadata is loaded', () {
    final loaderStart = source.indexOf(
      'Future<void> _loadLastVerifiedExportZipPath([String? workspacePath]) async {',
    );
    final loaderEnd = source.indexOf(
      'Future<File?> _lastSyncMetadataFile',
      loaderStart,
    );
    final loader = source.substring(loaderStart, loaderEnd);

    final clearIndex = loader.indexOf(
      'setState(() => _dashboardLastVerifiedExportZipPath = null);',
    );
    final decodeIndex = loader.indexOf('jsonDecode(await file.readAsString())');

    expect(clearIndex, greaterThanOrEqualTo(0));
    expect(decodeIndex, greaterThan(clearIndex));
  });

  test('metadata read failures are logged without restoring stale state', () {
    expect(
      source,
      contains('Posledný export ZIP sa nepodarilo načítať: \$error'),
    );
  });
}
