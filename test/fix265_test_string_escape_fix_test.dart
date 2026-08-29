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

  test('FIX267 keeps Release Manager on Build 317', () {
    final versionSource = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(versionSource, contains('static const int build = 317;'));
    expect(pubspec, contains('version: 8.0.0+317'));
  });
}
