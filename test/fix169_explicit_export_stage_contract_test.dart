import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  setUpAll(() => source = File('lib/main.dart').readAsStringSync());

  test('export supports explicit DEV RC FINAL stage', () {
    final start = source.indexOf('Future<File> _createOneClickReleaseZip');
    final end = source.indexOf('Future<void> _selectFileInExplorer', start);
    final block = source.substring(start, end);

    expect(block, contains('String? releaseStage,'));
    expect(block, contains('final normalizedRequestedStage = releaseStage'));
    expect(block, contains('final stage ='));
    expect(block, contains('normalizedRequestedStage.isEmpty'));
  });

  test('FAST/standalone stay DEV while controlled FULL BUILD may be FINAL', () {
    final oneClickIndex = source.indexOf('Future<void> _runOneClickBuild(');
    final exportIndex = source.indexOf(
      '_createOneClickReleaseZip(',
      oneClickIndex,
    );

    expect(oneClickIndex, greaterThanOrEqualTo(0));
    expect(exportIndex, greaterThan(oneClickIndex));

    // Controlled FULL BUILD passes its computed stage dynamically.
    expect(
      source.substring(oneClickIndex),
      contains("releaseStage: finalTransitionApplied ? 'FINAL' : 'DEV'"),
    );

    // Standalone/manual export remains explicitly DEV.
    expect(
      source,
      contains("releaseStage: 'DEV'"),
    );
  });

  test('One Click Release passes selected DEV RC FINAL mode to exporter', () {
    expect(
      source,
      contains('final combinedReleaseZip = await _createOneClickReleaseZip(\n          workspace,\n          releaseStage: selected,'),
    );
    expect(
      source,
      contains('final windowsOnlyReleaseZip = await _createOneClickReleaseZip(\n          workspace,\n          releaseStage: selected,'),
    );
  });
}
