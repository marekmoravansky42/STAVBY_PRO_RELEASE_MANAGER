import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX264 Release Manager build identity is synchronized', () {
    final versionSource = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    final buildMatch = RegExp(r'static const int build = (\d+);').firstMatch(versionSource);
    final versionMatch = RegExp(r"static const String version = '([^']+)';").firstMatch(versionSource);
    expect(buildMatch, isNotNull);
    expect(versionMatch, isNotNull);
    expect(versionSource, contains("RC1 DEV"));
    expect(pubspec, matches(RegExp('version: ${RegExp.escape(versionMatch!.group(1)!)}(?:-dev\\.\\d+)?\\+${buildMatch!.group(1)}\\b')));
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
