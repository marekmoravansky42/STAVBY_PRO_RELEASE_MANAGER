import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX251 project switch clears stale ZIP dashboard metadata', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains('_lastSynchronizedZipName = null;'));
    expect(source, contains('_dashboardLastVerifiedExportZipPath = null;'));
  });

  test('FIX251 project open reloads sync and export metadata for selected project', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(
      source,
      contains('() => _loadLastSynchronizedZipName(selected)'),
    );
    expect(
      source,
      contains('() => _loadLastVerifiedExportZipPath(selected)'),
    );
    expect(source, contains('FIX251 PROJECT ZIP METADATA:'));
  });
}
