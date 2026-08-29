import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX264 Release Manager build identity is synchronized', () {
    final versionSource = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(versionSource, contains('static const int build = 317;'));
    expect(versionSource, contains("RC1 DEV001 FIX267"));
    expect(pubspec, contains('version: 8.0.0+317'));
  });

  test('FIX264 badge derives build from canonical ReleaseManagerVersion', () {
    final versionSource = File('lib/app/app_version.dart').readAsStringSync();

    expect(
      versionSource,
      contains(r'''static const String badge = 'v$version $channel • Build $build • $stage';'''),
    );
    expect(
      versionSource,
      contains(r'''static const String label = '$version $channel Build $build $stage';'''),
    );
  });
}
