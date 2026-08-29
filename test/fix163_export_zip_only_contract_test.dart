import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unpacked release is kept in internal Integrity cache, not export root', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(
      source,
      contains("path.join(projectPath, '.release_integrity_cache')"),
    );
    expect(
      source,
      contains("path.join(releaseIntegrityCacheRoot.path, packageName)"),
    );
    expect(
      source,
      isNot(
        contains(
          "final registeredReleaseDirectory = Directory(\n      path.join(exportDirectory.path, packageName)",
        ),
      ),
    );
  });

  test('Distribution Center discovers internal Integrity cache after restart', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(
      source,
      contains("addRoot(path.join(workspace, '.release_integrity_cache'));"),
    );
  });

  test('export log explicitly keeps only resulting ZIP in export folder', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(
      source,
      contains('Export priečinok: ponechaný iba výsledný ZIP'),
    );
  });
}
