import 'dart:convert';

/// Complete reusable release configuration for one managed project.
class ReleaseProfile {
  const ReleaseProfile({
    required this.id,
    required this.name,
    this.windowsProjectPath,
    this.androidProjectPath,
    this.windowsExportDirectory,
    this.androidExportDirectory,
    this.managerUpdateDirectory,
    this.gitRepositoryPath,
    this.githubOwner,
    this.githubRepository,
    this.releasePackageName,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? windowsProjectPath;
  final String? androidProjectPath;
  final String? windowsExportDirectory;
  final String? androidExportDirectory;
  final String? managerUpdateDirectory;
  final String? gitRepositoryPath;
  final String? githubOwner;
  final String? githubRepository;
  final String? releasePackageName;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReleaseProfile copyWith({
    String? id,
    String? name,
    String? windowsProjectPath,
    String? androidProjectPath,
    String? windowsExportDirectory,
    String? androidExportDirectory,
    String? managerUpdateDirectory,
    String? gitRepositoryPath,
    String? githubOwner,
    String? githubRepository,
    String? releasePackageName,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReleaseProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      windowsProjectPath: windowsProjectPath ?? this.windowsProjectPath,
      androidProjectPath: androidProjectPath ?? this.androidProjectPath,
      windowsExportDirectory:
          windowsExportDirectory ?? this.windowsExportDirectory,
      androidExportDirectory:
          androidExportDirectory ?? this.androidExportDirectory,
      managerUpdateDirectory:
          managerUpdateDirectory ?? this.managerUpdateDirectory,
      gitRepositoryPath: gitRepositoryPath ?? this.gitRepositoryPath,
      githubOwner: githubOwner ?? this.githubOwner,
      githubRepository: githubRepository ?? this.githubRepository,
      releasePackageName: releasePackageName ?? this.releasePackageName,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'windowsProjectPath': windowsProjectPath,
        'androidProjectPath': androidProjectPath,
        'windowsExportDirectory': windowsExportDirectory,
        'androidExportDirectory': androidExportDirectory,
        'managerUpdateDirectory': managerUpdateDirectory,
        'gitRepositoryPath': gitRepositoryPath,
        'githubOwner': githubOwner,
        'githubRepository': githubRepository,
        'releasePackageName': releasePackageName,
        'isDefault': isDefault,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      }..removeWhere((_, value) => value == null);

  factory ReleaseProfile.fromJson(Map<String, Object?> json) {
    String? optionalString(String key) {
      final value = json[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    DateTime? optionalDate(String key) {
      final value = optionalString(key);
      return value == null ? null : DateTime.tryParse(value);
    }

    return ReleaseProfile(
      id: (json['id']?.toString() ?? '').trim(),
      name: (json['name']?.toString() ?? '').trim(),
      windowsProjectPath: optionalString('windowsProjectPath'),
      androidProjectPath: optionalString('androidProjectPath'),
      windowsExportDirectory: optionalString('windowsExportDirectory'),
      androidExportDirectory: optionalString('androidExportDirectory'),
      managerUpdateDirectory: optionalString('managerUpdateDirectory'),
      gitRepositoryPath: optionalString('gitRepositoryPath'),
      githubOwner: optionalString('githubOwner'),
      githubRepository: optionalString('githubRepository'),
      releasePackageName: optionalString('releasePackageName'),
      isDefault: json['isDefault'] == true,
      createdAt: optionalDate('createdAt'),
      updatedAt: optionalDate('updatedAt'),
    );
  }

  String encode({bool pretty = true}) {
    final encoder = pretty
        ? const JsonEncoder.withIndent('  ')
        : const JsonEncoder();
    return encoder.convert(toJson());
  }
}
