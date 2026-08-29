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
      "databaseName": "stavby_pro_dev.db"
    },
    "final": {
      "status": "FINAL",
      "androidApplicationId": "com.example.stavby_pro",
      "androidLabel": "STAVBY PRO",
      "dataRootName": "STAVBY_PRO",
      "databaseName": "stavby_pro.db"
    }
  }
}
''') as Map).map((k, v) => MapEntry(k.toString(), v)),
      );

  test('FIX249 builds deterministic DEV to FINAL transition plan', () {
    final plan = profile().planTransition('final');
    expect(plan.fromChannel, 'dev');
    expect(plan.toChannel, 'final');
    expect(plan.from.androidApplicationId, 'com.example.stavby_pro.dev');
    expect(plan.to.androidApplicationId, 'com.example.stavby_pro');
    expect(plan.from.dataRootName, 'STAVBY_PRO_DEV');
    expect(plan.to.dataRootName, 'STAVBY_PRO');
    expect(plan.from.databaseName, 'stavby_pro_dev.db');
    expect(plan.to.databaseName, 'stavby_pro.db');
  });

  test('FIX250 supersedes FIX249 dry-run with explicit preflight gate', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('FIX253 FINAL PREFLIGHT:'));
    expect(source, contains('await _confirmReleaseTransition(finalPlan)'));
    expect(
      source,
      contains('FIX253 FINAL APPLY:'),
    );
    expect(source, isNot(contains('writeAsString(finalPlan')));
  });
}
