import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX265 regression source remains valid Dart after SAFE MODE sync', () {
    final source = File(
      'test/fix264_release_manager_build_identity_sync_test.dart',
    ).readAsStringSync();

    expect(
      source,
      contains(
        r'''static const String badge = 'v$version $channel • Build $build • $stage';''',
      ),
    );
    expect(
      source,
      contains(
        r'''static const String label = '$version $channel Build $build $stage';''',
      ),
    );
  });

  test('canonical Release Manager build is present', () {
    final versionSource = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    final buildMatch = RegExp(r'static const int build = (\d+);').firstMatch(versionSource);
    final versionMatch = RegExp(r"static const String version = '([^']+)';").firstMatch(versionSource);
    expect(buildMatch, isNotNull);
    expect(versionMatch, isNotNull);
    expect(pubspec, matches(RegExp('version: ${RegExp.escape(versionMatch!.group(1)!)}(?:-dev\\.\\d+)?\\+${buildMatch!.group(1)}\\b')));
  });
}
