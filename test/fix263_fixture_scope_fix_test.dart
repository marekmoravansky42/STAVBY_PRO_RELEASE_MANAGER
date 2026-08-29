import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX263 FIX252 Windows fixture uses the existing root temp directory', () {
    final source =
        File('test/fix252_final_transition_apply_engine_test.dart')
            .readAsStringSync();

    expect(
      source,
      contains("path.join(root.path, 'windows/runner/main.cpp')"),
    );
    expect(
      source,
      contains("path.join(root.path, 'windows/runner/Runner.rc')"),
    );
    expect(
      source,
      isNot(contains("path.join(workspace.path, 'windows/runner/")),
    );
  });

  test('FIX263 canonical identity is current', () {
    final source = File('lib/app/app_version.dart').readAsStringSync();
    expect(source, contains("RC1 DEV001 FIX267"));
  });
}
