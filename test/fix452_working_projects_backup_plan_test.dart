import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/core/backup/working_projects_backup_plan.dart';

void main() {
  test('FIX452 creates a recoverable source snapshot plan for both projects',
      () {
    final createdAt = DateTime(2026, 9, 14, 10, 30, 45);
    final fileName = WorkingProjectsBackupPlan.archiveFileName(createdAt);
    final manifest = jsonDecode(
      WorkingProjectsBackupPlan.manifestJson(
        createdAt: createdAt,
        stavbyProPath: r'C:\SP\STAVBY_PRO',
        releaseManagerPath: r'C:\SP\Release_Manager',
        releaseManagerVersion: '8.0.0 RC1 Build 333 RC1 DEV015 FIX452',
      ),
    ) as Map<String, dynamic>;

    expect(fileName, 'WORKING_PROJECTS_BACKUP_20260914_103045.zip');
    expect(manifest['format'], 'STAVBY_PRO_WORKING_PROJECTS_BACKUP');
    expect(manifest['projects']['STAVBY_PRO'], r'C:\SP\STAVBY_PRO');
    expect(manifest['projects']['Release_Manager'], r'C:\SP\Release_Manager');
    expect(manifest['archiveDirectories'], <String>[
      'STAVBY_PRO',
      'Release_Manager',
    ]);
    expect(
        WorkingProjectsBackupPlan.excludedDirectories,
        containsAll(<String>[
          '.git',
          '.dart_tool',
          'build',
        ]));
  });
}
