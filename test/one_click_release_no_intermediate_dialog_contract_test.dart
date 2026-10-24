import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('One Click Release suppresses embedded FULL BUILD completion dialog', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf('Future<void> _runOneClickReleaseComplete()');
    final end = source.indexOf('Future<bool> _applyReleaseRecipe', start);
    final block = source.substring(start, end);

    expect(block, contains('showCompletionDialog: false'));
    expect(block, contains('exportReleaseZip: false'));
  });

  test('standalone One Click Build still defaults completion dialog on', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(
      source,
      contains(
        'bool exportReleaseZip = true',
      ),
    );
    expect(source, contains('bool showCompletionDialog = true'));
  });
}
