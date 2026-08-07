class ReleaseMetadata {
  const ReleaseMetadata({
    required this.projectName,
    required this.version,
    required this.build,
    required this.changes,
    this.generatedAt,
  });

  final String projectName;
  final String version;
  final int build;
  final List<String> changes;
  final DateTime? generatedAt;

  DateTime get timestamp => generatedAt ?? DateTime.now();
  String get versionLabel => '$version+$build';
}
