import 'dart:io';

import 'package:path/path.dart' as path;

import '../release/artifact_definition.dart';
import '../release/release_metadata.dart';
import '../release/release_report.dart';
import '../release/release_step.dart';
import '../testing/quality_report.dart';
import 'artifact_service.dart';
import 'changelog_service.dart';
import 'release_engine.dart';

class SmartReleaseResult {
  const SmartReleaseResult({
    required this.releaseReport,
    required this.releaseDirectory,
    required this.archivePath,
  });

  final ReleaseReport releaseReport;
  final String releaseDirectory;
  final String archivePath;
}

class SmartReleaseService {
  const SmartReleaseService({
    this.releaseEngine = const ReleaseEngine(),
    this.changelogService = const ChangelogService(),
    this.artifactService = const ArtifactService(),
  });

  final ReleaseEngine releaseEngine;
  final ChangelogService changelogService;
  final ArtifactService artifactService;

  Future<SmartReleaseResult> run({
    required ReleaseMetadata metadata,
    required String exportRoot,
    required QualityReport qualityReport,
    required List<ArtifactDefinition> artifacts,
    List<ReleaseStepDefinition> preExportSteps = const <ReleaseStepDefinition>[],
    void Function(ReleaseStepResult result)? onStepChanged,
  }) async {
    if (!qualityReport.qualityGatePassed) {
      throw StateError('Quality Gate zlyhal. Release bol zablokovaný.');
    }

    final folderName = '${metadata.projectName.replaceAll(' ', '_')}_${metadata.version}_${metadata.build}';
    final releaseDirectory = path.join(exportRoot, folderName);
    final archivePath = path.join(
      releaseDirectory,
      'archive',
      '$folderName.zip',
    );

    final steps = <ReleaseStepDefinition>[
      ...preExportSteps,
      ReleaseStepDefinition(
        id: 'prepare_layout',
        title: 'Prepare Release Layout',
        execute: () async {
          await artifactService.prepareReleaseLayout(releaseDirectory);
          return releaseDirectory;
        },
      ),
      ReleaseStepDefinition(
        id: 'quality_reports',
        title: 'Copy Quality Reports',
        execute: () async {
          final reports = Directory(path.join(releaseDirectory, 'reports'));
          await reports.create(recursive: true);
          await File(path.join(reports.path, 'quality_report.json'))
              .writeAsString(qualityReport.toPrettyJson());
          await File(path.join(reports.path, 'quality_report.txt'))
              .writeAsString(qualityReport.toText());
          return 'Quality reporty boli vytvorené.';
        },
      ),
      ReleaseStepDefinition(
        id: 'changelog',
        title: 'Generate Changelog',
        execute: () async {
          await changelogService.generate(
            metadata: metadata,
            outputDirectory: path.join(releaseDirectory, 'changelog'),
            qualityGateSummary: qualityReport.toText(),
          );
          return 'CHANGELOG.md a release_notes.txt boli vytvorené.';
        },
      ),
      ReleaseStepDefinition(
        id: 'artifacts',
        title: 'Collect Artifacts',
        execute: () async {
          final results = await artifactService.collect(
            releaseRoot: releaseDirectory,
            artifacts: artifacts,
          );
          return '${results.where((item) => item.copied).length} artefaktov skopírovaných.';
        },
      ),
      ReleaseStepDefinition(
        id: 'archive',
        title: 'Create ZIP Archive',
        execute: () async {
          await artifactService.createZip(
            sourceDirectory: releaseDirectory,
            archivePath: archivePath,
          );
          return archivePath;
        },
      ),
    ];

    final report = await releaseEngine.run(
      version: metadata.version,
      build: metadata.build,
      steps: steps,
      onStepChanged: onStepChanged,
    );

    final reportDirectory = Directory(path.join(releaseDirectory, 'reports'));
    await reportDirectory.create(recursive: true);
    await File(path.join(reportDirectory.path, 'release_report.txt'))
        .writeAsString(report.toText());

    return SmartReleaseResult(
      releaseReport: report,
      releaseDirectory: releaseDirectory,
      archivePath: archivePath,
    );
  }
}
