import 'release_profile.dart';
import 'release_profile_storage.dart';
import 'release_profile_validator.dart';

/// High-level operations for reusable release configurations.
class ReleaseProfileManager {
  ReleaseProfileManager({ReleaseProfileStorage? storage})
      : _storage = storage ?? ReleaseProfileStorage();

  final ReleaseProfileStorage _storage;
  final ReleaseProfileValidator _validator = const ReleaseProfileValidator();

  Future<List<ReleaseProfile>> loadProfiles() => _storage.load();

  Future<ReleaseProfile?> loadDefaultProfile() async {
    final profiles = await loadProfiles();
    for (final profile in profiles) {
      if (profile.isDefault) return profile;
    }
    return profiles.isEmpty ? null : profiles.first;
  }

  Future<List<ReleaseProfile>> upsert(ReleaseProfile profile) async {
    _validator.requireValid(profile);
    final now = DateTime.now();
    final profiles = (await loadProfiles()).toList();
    final index = profiles.indexWhere((item) => item.id == profile.id);
    final saved = profile.copyWith(
      createdAt: index < 0 ? (profile.createdAt ?? now) : profiles[index].createdAt,
      updatedAt: now,
    );
    if (saved.isDefault) {
      for (var i = 0; i < profiles.length; i++) {
        profiles[i] = profiles[i].copyWith(isDefault: false);
      }
    }
    if (index < 0) {
      profiles.add(saved);
    } else {
      profiles[index] = saved;
    }
    await _storage.save(profiles);
    return List<ReleaseProfile>.unmodifiable(profiles);
  }

  Future<List<ReleaseProfile>> remove(String profileId) async {
    final profiles = (await loadProfiles())
        .where((profile) => profile.id != profileId)
        .toList();
    if (profiles.isNotEmpty && !profiles.any((profile) => profile.isDefault)) {
      profiles[0] = profiles[0].copyWith(isDefault: true);
    }
    await _storage.save(profiles);
    return List<ReleaseProfile>.unmodifiable(profiles);
  }

  Future<List<ReleaseProfile>> setDefault(String profileId) async {
    final profiles = (await loadProfiles())
        .map((profile) => profile.copyWith(isDefault: profile.id == profileId))
        .toList();
    if (!profiles.any((profile) => profile.id == profileId)) {
      throw ArgumentError.value(profileId, 'profileId', 'Profil neexistuje.');
    }
    await _storage.save(profiles);
    return List<ReleaseProfile>.unmodifiable(profiles);
  }
}
