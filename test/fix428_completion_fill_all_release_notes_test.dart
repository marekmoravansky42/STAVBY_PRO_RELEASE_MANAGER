import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'FIX428 Fill all transfers history proposal into both Release Notes fields',
      () {
    final source = File('lib/main.dart').readAsStringSync();
    final labelOffset = source.indexOf("label: const Text('VYPLNIŤ VŠETKO')");

    expect(labelOffset, greaterThanOrEqualTo(0));
    final button = source.substring(
      source.lastIndexOf('FilledButton.tonalIcon(', labelOffset),
      labelOffset,
    );

    expect(button, contains('await suggestedReleaseNotesFromHistory()'));
    expect(
      button,
      contains(
        RegExp(r'releaseNewsController\.text\s*=\s*releaseNotes\.news'),
      ),
    );
    expect(
      button,
      contains(
        RegExp(r'releaseFixesController\.text\s*=\s*releaseNotes\.fixes'),
      ),
    );
    expect(
      button,
      contains(
        RegExp(
          r'commitController\.text\s*=\s*suggestedCommitMessage\(\)',
        ),
      ),
    );
    expect(
      button,
      contains(
        RegExp(r'changesController\.text\s*=\s*suggestedDescription\(\)'),
      ),
    );
  });
}
