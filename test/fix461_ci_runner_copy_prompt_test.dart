import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX461 copied CI failure includes a clear Codex repair request', () {
    final source = File(
      'lib/features/release_pipeline_designer/release_pipeline_designer_page.dart',
    ).readAsStringSync();

    expect(source, contains('ŽIADOSŤ PRE CHATGPT/CODEX'));
    expect(source, contains('Analyzuj túto chybu Release Managera'));
    expect(source, contains('nevytváraj commit, push ani publikovanie'));
    expect(source, contains('CI RUNNER – CHYBA'));
  });
}
