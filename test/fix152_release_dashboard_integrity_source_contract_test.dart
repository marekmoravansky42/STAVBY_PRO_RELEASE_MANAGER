import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Distribution Center parses numeric BUILD suffix', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('int releaseBuildNumber(Directory directory)'));
    expect(source, contains(r"RegExp(r'BUILD[_-]?(\d+)').firstMatch(name)"));
    expect(
      source,
      isNot(contains(r"RegExp(r'BUILD[_-]?(\\d+)').firstMatch(name)")),
    );
    expect(
      source,
      contains(
        'releaseBuildNumber(b).compareTo(releaseBuildNumber(a))',
      ),
    );
  });

  test('Release Dashboard readiness includes Release Integrity', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(
      source,
      contains(
        "final integrityOk = _dashboardReleaseIntegrityStatus == 'INTEGRITY OK';",
      ),
    );
    expect(source, contains('releaseAvailable && integrityOk'));
    expect(source, contains("title: 'Release Integrity'"));
    expect(source, contains("title: 'Publish Gate'"));
  });
}
