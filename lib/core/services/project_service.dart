import 'dart:convert';
import 'dart:io';

import '../projects/project_profile.dart';
import '../config/configuration_manager.dart';

/// Loads and persists project profiles without coupling them to the UI.
class ProjectService {
  const ProjectService();

  String get defaultProfilesDirectory =>
      '${ConfigurationManager.instance.configurationFile.parent.path}${Platform.pathSeparator}Profiles';

  Future<List<ProjectProfile>> loadProfiles(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return const <ProjectProfile>[];
    }

    final profiles = <ProjectProfile>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.json')) {
        continue;
      }
      final source = await entity.readAsString();
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Projektový profil musí byť JSON objekt.');
      }
      final profile = ProjectProfile.fromJson(decoded);
      validate(profile);
      profiles.add(profile);
    }

    profiles.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return List<ProjectProfile>.unmodifiable(profiles);
  }

  Future<void> saveProfile(
    String directoryPath,
    ProjectProfile profile,
  ) async {
    validate(profile);
    final directory = Directory(directoryPath);
    await directory.create(recursive: true);
    final safeId = profile.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${directory.path}${Platform.pathSeparator}$safeId.json');
    await file.writeAsString('${profile.encode()}\n', flush: true);
  }


  Future<void> deleteProfile(String directoryPath, String profileId) async {
    final safeId = profileId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('$directoryPath${Platform.pathSeparator}$safeId.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  ProjectProfile? activeProfile(Iterable<ProjectProfile> profiles) {
    for (final profile in profiles) {
      if (profile.isActive) {
        return profile;
      }
    }
    return profiles.isEmpty ? null : profiles.first;
  }

  List<ProjectProfile> activate(
    Iterable<ProjectProfile> profiles,
    String profileId,
  ) {
    var found = false;
    final result = profiles.map((profile) {
      final active = profile.id == profileId;
      found = found || active;
      return profile.copyWith(isActive: active);
    }).toList(growable: false);
    if (!found) {
      throw ArgumentError.value(profileId, 'profileId', 'Profil neexistuje.');
    }
    return result;
  }

  void validate(ProjectProfile profile) {
    if (profile.id.isEmpty) {
      throw const FormatException('Profil nemá ID.');
    }
    if (profile.name.isEmpty) {
      throw const FormatException('Profil nemá názov.');
    }
    if (profile.projectPath.isEmpty) {
      throw const FormatException('Profil nemá cestu projektu.');
    }
    if (profile.flutterExecutable.isEmpty) {
      throw const FormatException('Profil nemá Flutter executable.');
    }
    const supported = <String>{'windows', 'android'};
    if (profile.platforms.any((platform) => !supported.contains(platform))) {
      throw const FormatException('Profil obsahuje nepodporovanú platformu.');
    }
  }
}
