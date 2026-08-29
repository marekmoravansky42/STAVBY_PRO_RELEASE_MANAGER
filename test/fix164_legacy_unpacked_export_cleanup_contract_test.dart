import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy unpacked duplicate is removed only when paired ZIP exists', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(
      source,
      contains('Future<int> _cleanupLegacyUnpackedExportDirectories'),
    );
    expect(source, contains("final pairedZip = File('\${entity.path}.zip');"));
    expect(source, contains('if (!await pairedZip.exists()) continue;'));
    expect(source, contains('await entity.delete(recursive: true);'));
    expect(
      source,
      contains('removedLegacyDirectories ='),
    );
  });

  test('cleanup is restricted to historical One Click unpacked package names', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains("upper.contains('_BUILD_')"));
    expect(source, contains("upper.endsWith('_WINDOWS_RELEASE')"));
    expect(source, contains("upper.endsWith('_WINDOWS_ANDROID_RELEASE')"));
  });
}
