import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('One Click Release promotes verified ZIP to a non-null local', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains('final verifiedReleaseZip = finalReleaseZip;'));
    expect(source, contains('!await verifiedReleaseZip.exists()'));
    expect(source, contains('await verifiedReleaseZip.length() <= 0'));
    expect(
      source,
      contains('_dashboardLastVerifiedExportZipPath = verifiedReleaseZip.path;'),
    );
    expect(
      source,
      contains('ONE CLICK RELEASE EXPORT GATE OK: \${verifiedReleaseZip.path}'),
    );
  });

  test('completion UI uses the physically verified ZIP directly', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains('Export:\\n\${verifiedReleaseZip.path}'));
    expect(
      source,
      contains('_selectFileInExplorer(verifiedReleaseZip.path)'),
    );
  });
}
