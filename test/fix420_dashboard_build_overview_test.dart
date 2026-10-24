import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX420 dashboard shows only completed build steps as green checks', () {
    final source = File('lib/main.dart').readAsStringSync();
    final quickOverview = source.substring(
      source.indexOf("final quickOverview = RMSectionCard("),
      source.indexOf("final lastBuild = RMSectionCard("),
    );
    final lastBuild = source.substring(
      source.indexOf("final lastBuild = RMSectionCard("),
      source.indexOf('double get _oneClickBuildProgress'),
    );

    expect(quickOverview, isNot(contains("'Projekt'")));
    expect(lastBuild, contains("'Android APK'"));
    expect(lastBuild, contains('_dashboardBuildAndroidOk'));
    expect(lastBuild, contains(r'Trvanie: ${_formatDashboardBuildElapsed('));
    expect(source, contains('_dashboardBuildAnalyzeOk = false'));
    expect(source, contains('_dashboardBuildTestOk = false'));
    expect(source, contains('_dashboardBuildWindowsOk = false'));
    expect(source, contains('_dashboardBuildAndroidOk = false'));
    expect(source, contains('_dashboardBuildExportOk = false'));
    expect(
      source,
      contains(
          "if (label == 'Android APK Release build') {\n            _dashboardBuildAndroidOk = true;"),
    );
  });
}
