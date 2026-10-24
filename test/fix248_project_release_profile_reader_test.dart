import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/core/projects/project_release_profile.dart';

void main() {
  test('FIX248 parses STAVBY PRO DEV and FINAL identities', () {
    final profile = ProjectReleaseProfile.fromJson(
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

    expect(profile.activeChannel, 'dev');
    expect(profile.dev.androidApplicationId, 'com.example.stavby_pro.dev');
    expect(profile.dev.dataRootName, 'STAVBY_PRO_DEV');
    expect(profile.finalChannel.androidApplicationId, 'com.example.stavby_pro');
    expect(profile.finalChannel.databaseName, 'stavby_pro.db');
    expect(profile.finalChannel.windowsBinaryName, 'stavby_pro');
  });

  test('FIX248 FULL BUILD integration is read-only and fail-safe', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('ProjectReleaseProfile.tryLoad(workspace)'));
    expect(source, contains('Projektový Release Profile je neplatný'));
    expect(source, contains('FIX253 Release Profile:'));
    expect(source, isNot(contains('writeAsString(releaseProfile')));
  });
}
