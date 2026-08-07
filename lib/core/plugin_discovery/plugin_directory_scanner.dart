import 'dart:io';

import 'plugin_manifest.dart';
import 'plugin_manifest_parser.dart';
import 'plugin_scan_issue.dart';
import 'plugin_scan_result.dart';

class PluginDirectoryScanner {
  const PluginDirectoryScanner({
    this.parser = const PluginManifestParser(),
    this.manifestFileName = 'plugin.json',
  });

  final PluginManifestParser parser;
  final String manifestFileName;

  Future<PluginScanResult> scan(Directory directory) async {
    if (!await directory.exists()) {
      return PluginScanResult(
        issues: <PluginScanIssue>[
          PluginScanIssue(
            type: PluginScanIssueType.directoryMissing,
            path: directory.path,
            message: 'Adresár pluginov neexistuje: ${directory.path}',
          ),
        ],
      );
    }

    final manifests = <PluginManifest>[];
    final issues = <PluginScanIssue>[];
    final manifestById = <String, String>{};

    try {
      await for (final entity in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File || _fileName(entity.path) != manifestFileName) {
          continue;
        }

        try {
          final source = await entity.readAsString();
          final validation = parser.parse(source);
          final manifest = validation.value;

          if (!validation.isValid || manifest == null) {
            issues.add(
              PluginScanIssue(
                type: PluginScanIssueType.invalidManifest,
                path: entity.path,
                message: validation.errors.join(' '),
              ),
            );
            continue;
          }

          final previousPath = manifestById[manifest.id];
          if (previousPath != null) {
            issues.add(
              PluginScanIssue(
                type: PluginScanIssueType.duplicatePluginId,
                path: entity.path,
                pluginId: manifest.id,
                message: 'Duplicitné ID pluginu "${manifest.id}". '
                    'Prvý manifest: $previousPath',
              ),
            );
            continue;
          }

          manifestById[manifest.id] = entity.path;
          manifests.add(manifest);
        } on FileSystemException catch (error) {
          issues.add(
            PluginScanIssue(
              type: PluginScanIssueType.readFailed,
              path: entity.path,
              message: 'Manifest sa nepodarilo načítať: ${error.message}',
            ),
          );
        }
      }
    } on FileSystemException catch (error) {
      issues.add(
        PluginScanIssue(
          type: PluginScanIssueType.readFailed,
          path: directory.path,
          message: 'Adresár pluginov sa nepodarilo prehľadať: ${error.message}',
        ),
      );
    }

    manifests.sort((a, b) => a.id.compareTo(b.id));
    return PluginScanResult(
      manifests: List<PluginManifest>.unmodifiable(manifests),
      issues: List<PluginScanIssue>.unmodifiable(issues),
    );
  }

  String _fileName(String path) =>
      path.split(Platform.pathSeparator).where((part) => part.isNotEmpty).last;
}
