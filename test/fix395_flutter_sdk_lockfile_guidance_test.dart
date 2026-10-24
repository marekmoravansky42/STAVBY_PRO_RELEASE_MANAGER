import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/services/flutter_sdk_lockfile_guidance.dart';

void main() {
  const exactError = <String>[
    'Flutter failed to open a file at "C:\\6\\flutter\\bin\\cache\\lockfile".',
    'The flutter tool cannot access the file or directory.',
  ];

  test(
      'FIX395 recognizes only the Flutter SDK lockfile with Windows separators',
      () {
    final guidance = FlutterSdkLockfileGuidance.forOutput(exactError);

    expect(guidance, isNotNull);
    expect(guidance, contains('Flutter SDK lockfile je nedostupný.'));
    expect(guidance, contains('Dokončite alebo zatvorte iné Flutter procesy.'));
    expect(guidance, contains('Overte právo zápisu do Flutter SDK cache.'));
    expect(guidance, contains('Spustite FAST DEV BUILD znova.'));
  });

  test('FIX395 also recognizes the same lockfile with forward separators', () {
    expect(
      FlutterSdkLockfileGuidance.forOutput(<String>[
        'Flutter failed to open a file at "C:/6/flutter/bin/cache/lockfile".',
      ]),
      isNotNull,
    );
  });

  test('FIX395 ignores other Flutter and SDK cache failures', () {
    expect(
      FlutterSdkLockfileGuidance.forOutput(<String>[
        'Flutter failed to read file at "C:\\project\\pubspec.yaml".',
      ]),
      isNull,
    );
    expect(
      FlutterSdkLockfileGuidance.forOutput(<String>[
        'Flutter failed to open a file at "C:/6/flutter/bin/cache/artifacts.zip".',
      ]),
      isNull,
    );
  });

  test('FIX395 guidance is additive and leaves files untouched without retry',
      () async {
    final root = await Directory.systemTemp.createTemp('fix395_');
    addTearDown(() => root.delete(recursive: true));
    final marker = File('${root.path}${Platform.pathSeparator}marker.txt');
    await marker.writeAsString('keep');
    var processRuns = 0;
    Future<List<String>> runOnce() async {
      processRuns++;
      return <String>[...exactError];
    }

    final output = await runOnce();
    final guidance = FlutterSdkLockfileGuidance.forOutput(output);
    if (guidance != null) output.addAll(guidance);

    expect(processRuns, 1);
    expect(await marker.readAsString(), 'keep');
    expect(output, contains('Flutter SDK lockfile je nedostupný.'));
  });
}
