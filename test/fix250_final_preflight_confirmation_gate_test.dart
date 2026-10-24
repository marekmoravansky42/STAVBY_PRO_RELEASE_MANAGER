import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/core/projects/project_release_profile.dart';

void main() {
  ProjectReleaseProfile profile() => ProjectReleaseProfile.fromJson(
        (jsonDecode('''
{
  "schemaVersion": 1,
  "projectId": "stavby_pro",
  "displayName": "STAVBY PRO",
  "identityFile": "lib/core/app/app_identity.dart",
  "activeChannel": "dev",
  "channels": {
    "dev": {
      "status": "DEV",
      "androidApplicationId": "com.example.stavby_pro.dev",
      "androidLabel": "STAVBY PRO DEV",
      "dataRootName": "STAVBY_PRO_DEV",
      "databaseName": "stavby_pro_dev.db",
      "windowsBinaryName": "stavby_pro_dev"
    },
    "final": {
      "status": "FINAL",
      "androidApplicationId": "com.example.stavby_pro",
      "androidLabel": "STAVBY PRO",
      "dataRootName": "STAVBY_PRO",
      "databaseName": "stavby_pro.db",
      "windowsBinaryName": "stavby_pro"
    }
  }
}
''') as Map).map((k, v) => MapEntry(k.toString(), v)),
      );

  test('FIX250 preflight preview lists every critical DEV to FINAL change', () {
    final preview = profile().planTransition('final').previewText;
    expect(preview, contains('com.example.stavby_pro.dev'));
    expect(preview, contains('com.example.stavby_pro'));
    expect(preview, contains('STAVBY_PRO_DEV'));
    expect(preview, contains('STAVBY_PRO'));
    expect(preview, contains('stavby_pro_dev.db'));
    expect(preview, contains('stavby_pro.db'));
    expect(profile().finalChannel.windowsBinaryName, 'stavby_pro');
    expect(preview, contains('lib/core/app/app_identity.dart'));
  });

  test('FIX250 requires explicit non-dismissible confirmation', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('barrierDismissible: false'));
    expect(source, contains('Skontrolované • Pokračovať'));
    expect(source, contains("child: const Text('Zrušiť')"));
    expect(source, contains('await _confirmReleaseTransition(finalPlan)'));
  });

  test('FIX250 cancellation leaves project unchanged', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('projekt zostal bez zmien.'));
  });

  test('FIX250 still does not write FINAL transition to project', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(
      source,
      contains('FIX253 FINAL APPLY:'),
    );
    expect(source, isNot(contains('writeAsString(finalPlan')));
  });
}
