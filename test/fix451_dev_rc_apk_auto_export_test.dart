import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('lib/main.dart').readAsStringSync();

  test('FIX451 copies STAVBY PRO Android APK after DEV or RC ZIP export', () {
    final start = source.indexOf('Future<File> _createOneClickReleaseZip(');
    final end = source.indexOf('Future<void> _refreshDistributionCenterFromDisk', start);
    final method = source.substring(start, end);
    expect(method, contains("const <String>{'DEV', 'RC'}.contains(stage)"));
    expect(method, contains('_androidReleaseExportDirectory?.trim()'));
    expect(method, contains(r'''${currentProject.releaseFileStem}.apk'''));
    expect(method, contains(r'Android APK pre $stage skopírované'));
    expect(method, contains('while (await outputFile.exists())'));
    expect(method, contains(r'_$duplicateIndex.apk'));
  });
}