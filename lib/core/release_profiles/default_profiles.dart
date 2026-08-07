import 'release_profile.dart';

abstract final class DefaultReleaseProfiles {
  static ReleaseProfile stavbyPro({
    required String windowsProjectPath,
    required String androidProjectPath,
    String? windowsExportDirectory,
    String? androidExportDirectory,
    String? managerUpdateDirectory,
  }) {
    return ReleaseProfile(
      id: 'stavby_pro',
      name: 'STAVBY PRO',
      windowsProjectPath: windowsProjectPath.trim(),
      androidProjectPath: androidProjectPath.trim(),
      windowsExportDirectory: windowsExportDirectory,
      androidExportDirectory: androidExportDirectory,
      managerUpdateDirectory: managerUpdateDirectory,
      githubOwner: 'marekmoravansky42',
      githubRepository: 'stavby-pro-updates',
      releasePackageName: 'STAVBY_PRO',
      isDefault: true,
    );
  }
}
