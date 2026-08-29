import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('project profile flow checks mounted after async platform detection', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(
      source,
      contains(
        "if (await Directory(path.join(selected, 'android')).exists()) 'android',\n"
        "      ];\n"
        "      if (!mounted) return;\n"
        "      final profile = ProjectProfile(",
      ),
    );
  });

  test('project clone checks mounted after async name dialog', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(
      source,
      contains(
        "final name = await _askProfileName(\n"
        "      'Project Clone – názov nového profilu',\n"
        "      '\${profile.name} – klon',\n"
        "    );\n"
        "    if (name == null || !mounted) return;",
      ),
    );
  });
}
