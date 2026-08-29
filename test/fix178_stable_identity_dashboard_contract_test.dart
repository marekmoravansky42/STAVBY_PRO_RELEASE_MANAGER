import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String mainSource;
  late String versionSource;
  late String pubspec;

  setUpAll(() {
    mainSource = File('lib/main.dart').readAsStringSync();
    versionSource = File('lib/app/app_version.dart').readAsStringSync();
    pubspec = File('pubspec.yaml').readAsStringSync();
  });

  test('build identity remains single-source and matches pubspec build', () {
    final pubspecBuild =
        RegExp(r'^version:\s*[^+]+\+(\d+)', multiLine: true)
            .firstMatch(pubspec)!
            .group(1);
    final appBuild =
        RegExp(r'static const int build = (\d+);')
            .firstMatch(versionSource)!
            .group(1);

    expect(appBuild, pubspecBuild);
  });

  test('dashboard export row stays outside Last Build card', () {
    expect(mainSource, contains("'Posledný export ZIP'"));

    final lastBuildStart = mainSource.indexOf("title: 'Posledný build'");
    final lastBuildEnd = mainSource.indexOf('return Column(', lastBuildStart);
    final lastBuildBlock =
        mainSource.substring(lastBuildStart, lastBuildEnd);

    expect(
      lastBuildBlock,
      isNot(contains('_dashboardLastVerifiedExportZipPath')),
    );
  });

  test('manual export navigation remains available without FAST auto-open', () {
    expect(
      mainSource,
      isNot(contains('await _selectFileInExplorer(releaseZipFile.path);')),
    );
    expect(mainSource, contains('_selectFileInExplorer('));
    expect(mainSource, contains('_dashboardLastVerifiedExportZipPath!'));
  });

  test('release stage contract remains explicit', () {
    expect(mainSource, anyOf(contains("releaseStage: 'DEV'"), contains('releaseStage: releaseStage')));
    expect(mainSource, contains('releaseStage: selected,'));
  });
}
