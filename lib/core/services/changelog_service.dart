import 'dart:io';

import '../release/release_metadata.dart';

class ChangelogService {
  const ChangelogService();

  Future<List<File>> generate({
    required ReleaseMetadata metadata,
    required String outputDirectory,
    String qualityGateSummary = '',
  }) async {
    final directory = Directory(outputDirectory);
    await directory.create(recursive: true);

    final changelog = File(
      '${directory.path}${Platform.pathSeparator}CHANGELOG.md',
    );
    final notes = File(
      '${directory.path}${Platform.pathSeparator}release_notes.txt',
    );

    final date = metadata.timestamp.toIso8601String();
    final changes = metadata.changes.isEmpty
        ? '- Bez uvedených zmien.'
        : metadata.changes.map((item) => '- $item').join('\n');

    await changelog.writeAsString('''# ${metadata.projectName}\n\n## ${metadata.versionLabel}\n\nDátum: $date\n\n### Zmeny\n\n$changes\n${qualityGateSummary.trim().isEmpty ? '' : '\n### Quality Gate\n\n```text\n${qualityGateSummary.trim()}\n```\n'}''');

    await notes.writeAsString('''${metadata.projectName}\nRelease ${metadata.versionLabel}\nDátum: $date\n\nZmeny:\n${metadata.changes.isEmpty ? 'Bez uvedených zmien.' : metadata.changes.map((item) => '• $item').join('\n')}\n${qualityGateSummary.trim().isEmpty ? '' : '\nQuality Gate:\n${qualityGateSummary.trim()}\n'}''');

    return <File>[changelog, notes];
  }
}
