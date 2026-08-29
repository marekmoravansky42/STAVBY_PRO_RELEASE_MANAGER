import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File('lib/main.dart').readAsStringSync();
  });

  test('FAST DEV export stays explicitly DEV and does not auto-open Explorer', () {
    expect(source, anyOf(contains("releaseStage: 'DEV'"), contains('releaseStage: releaseStage')));
    expect(
      source,
      isNot(contains('await _selectFileInExplorer(releaseZipFile.path);')),
    );
  });

  test('One Click Release passes selected DEV RC FINAL stage to exporter', () {
    expect(
      source,
      contains(
        'final windowsOnlyReleaseZip = await _createOneClickReleaseZip(\n'
        '          workspace,\n'
        '          releaseStage: selected,',
      ),
    );
    expect(
      source,
      contains(
        'final combinedReleaseZip = await _createOneClickReleaseZip(\n'
        '          workspace,\n'
        '          releaseStage: selected,',
      ),
    );
  });

  test('physical ZIP gate remains before SHA-256 Integrity', () {
    final start =
        source.indexOf('Future<void> _runOneClickReleaseComplete() async');
    final end = source.indexOf('Future<bool> _applyReleaseRecipe', start);
    final block = source.substring(start, end);

    final gate = block.indexOf('ONE CLICK RELEASE EXPORT GATE OK:');
    final manifest = block.indexOf('Vytváram SHA-256 manifest...');
    expect(gate, greaterThanOrEqualTo(0));
    expect(manifest, greaterThan(gate));
  });

  test('RC FINAL restore project and selector to DEV', () {
    expect(source, contains("if (selected != 'DEV')"));
    expect(source, contains('await _restoreDevelopmentRecipe();'));
    expect(source, contains("_oneClickReleaseMode = 'DEV'"));
    expect(source, contains("saveOneClickReleaseMode('DEV')"));
  });

  test('user-facing export folder cleanup remains paired-ZIP safe', () {
    expect(
      source,
      contains('Future<int> _cleanupLegacyUnpackedExportDirectories'),
    );
    expect(source, contains("final pairedZip = File('\${entity.path}.zip');"));
    expect(source, contains('if (!await pairedZip.exists()) continue;'));
  });

  test('Dashboard keeps Last Export ZIP in Project Information', () {
    expect(source, contains("'Posledný export ZIP'"));
    expect(
      source,
      contains('path.basename(_dashboardLastVerifiedExportZipPath!)'),
    );
  });
}
