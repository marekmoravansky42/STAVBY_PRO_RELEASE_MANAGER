import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File('lib/main.dart').readAsStringSync();
  });

  test('DEV uses fast build while RC and FINAL use full build', () {
    final releaseStart = source.indexOf(
      'Future<void> _runOneClickReleaseComplete() async',
    );
    final releaseEnd = source.indexOf(
      'Future<bool> _applyReleaseRecipe',
      releaseStart,
    );
    final block = source.substring(releaseStart, releaseEnd);

    expect(block, contains("final fastDevRelease = selected == 'DEV';"));
    expect(
      block,
      contains('await _runOneClickBuild(\n        fastMode: fastDevRelease,'),
    );
  });

  test('RC and FINAL always restore the workspace back to DEV', () {
    final releaseStart = source.indexOf(
      'Future<void> _runOneClickReleaseComplete() async',
    );
    final releaseEnd = source.indexOf(
      'Future<bool> _applyReleaseRecipe',
      releaseStart,
    );
    final block = source.substring(releaseStart, releaseEnd);

    expect(block, contains("if (selected != 'DEV')"));
    expect(block, contains('await _restoreDevelopmentRecipe();'));
    expect(block, contains("_oneClickReleaseMode = 'DEV'"));
    expect(
      block,
      contains("saveOneClickReleaseMode('DEV')"),
    );
  });

  test('FINAL removes dev/rc suffix and DEV restores dev form', () {
    final recipeStart = source.indexOf(
      'Future<bool> _applyReleaseRecipe',
    );
    final recipeEnd = source.indexOf(
      'Future<void> _restoreDevelopmentRecipe',
      recipeStart,
    );
    final block = source.substring(recipeStart, recipeEnd);

    expect(block, contains("'FINAL' => baseVersion.replaceAll"));
    expect(block, contains("baseVersion.contains(RegExp(r'-dev'"));
    expect(
      block,
      contains("}-dev.1'"),
    );
  });

  test('physical Export ZIP gate runs before Release Integrity', () {
    final releaseStart = source.indexOf(
      'Future<void> _runOneClickReleaseComplete() async',
    );
    final releaseEnd = source.indexOf(
      'Future<bool> _applyReleaseRecipe',
      releaseStart,
    );
    final block = source.substring(releaseStart, releaseEnd);

    final exportGate = block.indexOf('ONE CLICK RELEASE EXPORT GATE OK:');
    final manifest = block.indexOf('Vytváram SHA-256 manifest...');
    final integrity = block.indexOf(
      'ONE CLICK RELEASE: 4/6 Release Integrity + Publish Gate OK.',
    );

    expect(exportGate, greaterThanOrEqualTo(0));
    expect(manifest, greaterThan(exportGate));
    expect(integrity, greaterThan(manifest));
  });

  test('completion dialog does not falsely claim Android for Windows-only project', () {
    expect(
      source,
      contains(
        "Android APK: \${androidProject ? 'OK' : '— (projekt bez Android platformy)'}",
      ),
    );
    expect(source, contains('Export ZIP: OK – fyzicky overený'));
  });
}
