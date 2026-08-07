class ArtifactDefinition {
  const ArtifactDefinition({
    required this.id,
    required this.sourcePath,
    required this.relativeTargetPath,
    this.required = true,
  });

  final String id;
  final String sourcePath;
  final String relativeTargetPath;
  final bool required;
}

class ArtifactResult {
  const ArtifactResult({
    required this.id,
    required this.sourcePath,
    required this.targetPath,
    required this.copied,
    required this.message,
  });

  final String id;
  final String sourcePath;
  final String targetPath;
  final bool copied;
  final String message;
}
