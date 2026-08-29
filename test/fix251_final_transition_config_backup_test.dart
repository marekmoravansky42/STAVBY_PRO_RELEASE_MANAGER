import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/core/projects/project_release_profile.dart';

void main() {
  test('FIX251 transition plan lists critical configuration files', () {
    expect(
      ProjectReleaseProfile.transitionConfigFiles,
      containsAll(<String>[
        'release/stavby_pro_release_profile.json',
        'lib/core/app/app_identity.dart',
        'lib/core/app/app_environment.dart',
        'android/app/build.gradle.kts',
        'android/app/src/main/AndroidManifest.xml',
        'pubspec.yaml',
      ]),
    );
  });

  test('FIX251 backs up configuration before future transition write', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('await _backupReleaseTransitionConfiguration('));
    expect(source, contains('.release_transition_backups'));
    expect(source, contains('transition_backup_manifest.json'));
    expect(source, contains('FIX251 CONFIG BACKUP:'));
    expect(
      source,
      contains('FIX253 FINAL APPLY:'),
    );
  });

  test('FIX251 fails when a mandatory config file is missing', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('chýba povinný konfiguračný súbor'));
  });
}
