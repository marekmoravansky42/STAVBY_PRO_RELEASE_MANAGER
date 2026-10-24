import 'dart:convert';

import 'package:path/path.dart' as path;

/// Describes a portable source snapshot of the two projects maintained here.
///
/// Generated build outputs and Git object databases are intentionally left out:
/// the archive is meant to recover the current editable sources and local
/// Release Manager settings, not to duplicate reproducible artifacts.
abstract final class WorkingProjectsBackupPlan {
  static const String format = 'STAVBY_PRO_WORKING_PROJECTS_BACKUP';

  static const List<String> excludedDirectories = <String>[
    '.git',
    '.dart_tool',
    'build',
  ];

  static String archiveFileName(DateTime createdAt) {
    String two(int value) => value.toString().padLeft(2, '0');
    return 'WORKING_PROJECTS_BACKUP_${createdAt.year.toString().padLeft(4, '0')}'
        '${two(createdAt.month)}${two(createdAt.day)}_'
        '${two(createdAt.hour)}${two(createdAt.minute)}${two(createdAt.second)}.zip';
  }

  static Map<String, Object?> manifest({
    required DateTime createdAt,
    required String stavbyProPath,
    required String releaseManagerPath,
    required String releaseManagerVersion,
  }) =>
      <String, Object?>{
        'format': format,
        'createdAt': createdAt.toIso8601String(),
        'releaseManagerVersion': releaseManagerVersion,
        'projects': <String, Object?>{
          'STAVBY_PRO': stavbyProPath,
          'Release_Manager': releaseManagerPath,
        },
        'archiveDirectories': <String>['STAVBY_PRO', 'Release_Manager'],
        'excludedDirectories': excludedDirectories,
        'restoreNote':
            'Rozbaľte do nového bezpečného umiestnenia; archív sám nič neobnovuje.',
      };

  static String manifestJson({
    required DateTime createdAt,
    required String stavbyProPath,
    required String releaseManagerPath,
    required String releaseManagerVersion,
  }) =>
      '${const JsonEncoder.withIndent('  ').convert(manifest(
        createdAt: createdAt,
        stavbyProPath: path.normalize(stavbyProPath),
        releaseManagerPath: path.normalize(releaseManagerPath),
        releaseManagerVersion: releaseManagerVersion,
      ))}\n';
}
