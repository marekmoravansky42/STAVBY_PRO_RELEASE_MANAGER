import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX261 transition backup includes Windows native identity files', () {
    final source =
        File('lib/core/projects/project_release_profile.dart').readAsStringSync();

    expect(source, contains("'windows/runner/main.cpp'"));
    expect(source, contains("'windows/runner/Runner.rc'"));
  });

  test('FIX261 transition applies and verifies Windows native label', () {
    final source = File(
      'lib/core/projects/project_release_transition_engine.dart',
    ).readAsStringSync();

    expect(source, contains("await rewrite('windows/runner/main.cpp'"));
    expect(source, contains("await rewrite('windows/runner/Runner.rc'"));
    expect(source, contains('target.androidLabel'));
    expect(source, contains('VALUE "FileDescription"'));
    expect(source, contains('VALUE "ProductName"'));
  });

  test('FIX261 canonical Release Manager badge is current', () {
    final source = File('lib/app/app_version.dart').readAsStringSync();
    expect(source, contains("RC1 DEV001 FIX267"));
  });
}
