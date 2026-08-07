import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'release_profile.dart';
import 'release_profile_validator.dart';

/// Persists all release profiles in one versioned JSON document.
class ReleaseProfileStorage {
  ReleaseProfileStorage({File? file}) : _fileOverride = file;

  final File? _fileOverride;
  final ReleaseProfileValidator _validator = const ReleaseProfileValidator();

  File get file {
    if (_fileOverride != null) return _fileOverride;
    final appData = Platform.environment['APPDATA'];
    final base = appData == null || appData.trim().isEmpty
        ? Directory.systemTemp.path
        : appData;
    return File(path.join(
      base,
      'STAVBY_PRO_RELEASE_MANAGER',
      'release_profiles.json',
    ));
  }

  Future<List<ReleaseProfile>> load() async {
    if (!await file.exists()) return const <ReleaseProfile>[];
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) {
      throw const FormatException('Súbor release profilov nie je JSON objekt.');
    }
    final rawProfiles = decoded['profiles'];
    if (rawProfiles is! List) return const <ReleaseProfile>[];

    final profiles = <ReleaseProfile>[];
    for (final item in rawProfiles) {
      if (item is! Map) continue;
      final profile = ReleaseProfile.fromJson(
        Map<String, Object?>.from(item),
      );
      _validator.requireValid(profile);
      profiles.add(profile);
    }
    profiles.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return List<ReleaseProfile>.unmodifiable(profiles);
  }

  Future<void> save(Iterable<ReleaseProfile> profiles) async {
    final normalized = profiles.toList(growable: false);
    for (final profile in normalized) {
      _validator.requireValid(profile);
    }
    final ids = normalized.map((profile) => profile.id).toSet();
    if (ids.length != normalized.length) {
      throw const FormatException('Release profily obsahujú duplicitné ID.');
    }
    if (normalized.where((profile) => profile.isDefault).length > 1) {
      throw const FormatException('Predvolený môže byť iba jeden profil.');
    }

    await file.parent.create(recursive: true);
    final document = <String, Object?>{
      'schemaVersion': 1,
      'updatedAt': DateTime.now().toIso8601String(),
      'profiles': normalized.map((profile) => profile.toJson()).toList(),
    };
    await file.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(document)}\n',
      flush: true,
    );
  }
}
