import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Git publisher guards context after async work', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(
      source,
      contains(
        'final defaultTagExists =\n'
        '        tagCheck.exitCode == 0 && tagCheck.stdout.toString().trim().isNotEmpty;\n\n'
        '    if (!mounted) return;',
      ),
    );
    expect(
      source,
      contains("text: remoteReady ? detectedOriginUrl : ''"),
    );
  });

  test('release package build interpolation is analyzer-clean', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains("_BUILD_\$build'"));
    expect(source, isNot(contains("_BUILD_\${build}'")));
  });
}
