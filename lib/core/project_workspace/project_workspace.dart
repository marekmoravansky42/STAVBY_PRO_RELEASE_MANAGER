import 'project_platform.dart';

class ProjectWorkspace {
  const ProjectWorkspace({
    required this.rootPath,
    required this.projectName,
    required this.platforms,
  });

  final String rootPath;
  final String projectName;
  final Set<ProjectPlatform> platforms;

  bool supports(ProjectPlatform platform) => platforms.contains(platform);
}
