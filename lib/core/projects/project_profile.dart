import 'dart:convert';

/// Persistent configuration of one managed Flutter project.
class ProjectProfile {
  const ProjectProfile({
    required this.id,
    required this.name,
    required this.projectPath,
    required this.exportPath,
    required this.gitRepository,
    required this.flutterExecutable,
    required this.platforms,
    this.gitBranch = 'develop',
    this.releaseType = 'DEV',
    this.isActive = false,
  });

  final String id;
  final String name;
  final String projectPath;
  final String exportPath;
  final String gitRepository;
  final String flutterExecutable;
  final List<String> platforms;
  final String gitBranch;
  final String releaseType;
  final bool isActive;

  bool get supportsWindows => platforms.contains('windows');
  bool get supportsAndroid => platforms.contains('android');

  ProjectProfile copyWith({
    String? id,
    String? name,
    String? projectPath,
    String? exportPath,
    String? gitRepository,
    String? flutterExecutable,
    List<String>? platforms,
    String? gitBranch,
    String? releaseType,
    bool? isActive,
  }) {
    return ProjectProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      projectPath: projectPath ?? this.projectPath,
      exportPath: exportPath ?? this.exportPath,
      gitRepository: gitRepository ?? this.gitRepository,
      flutterExecutable: flutterExecutable ?? this.flutterExecutable,
      platforms: platforms ?? this.platforms,
      gitBranch: gitBranch ?? this.gitBranch,
      releaseType: releaseType ?? this.releaseType,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'projectPath': projectPath,
        'exportPath': exportPath,
        'gitRepository': gitRepository,
        'flutterExecutable': flutterExecutable,
        'platforms': platforms,
        'gitBranch': gitBranch,
        'releaseType': releaseType,
        'isActive': isActive,
      };

  factory ProjectProfile.fromJson(Map<String, Object?> json) {
    final rawPlatforms = json['platforms'];
    return ProjectProfile(
      id: (json['id'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
      projectPath: (json['projectPath'] as String? ?? '').trim(),
      exportPath: (json['exportPath'] as String? ?? '').trim(),
      gitRepository: (json['gitRepository'] as String? ?? '').trim(),
      flutterExecutable:
          (json['flutterExecutable'] as String? ?? 'flutter').trim(),
      platforms: rawPlatforms is List
          ? rawPlatforms.whereType<String>().toList(growable: false)
          : const <String>[],
      gitBranch: (json['gitBranch'] as String? ?? 'develop').trim(),
      releaseType: (json['releaseType'] as String? ?? 'DEV').trim(),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  String encode({bool pretty = true}) {
    final encoder = pretty
        ? const JsonEncoder.withIndent('  ')
        : const JsonEncoder();
    return encoder.convert(toJson());
  }
}
