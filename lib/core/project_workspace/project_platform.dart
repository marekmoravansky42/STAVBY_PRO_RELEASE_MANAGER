enum ProjectPlatform { windows, android, web, linux, macos, ios }

extension ProjectPlatformLabel on ProjectPlatform {
  String get id => name;
  String get label => switch (this) {
        ProjectPlatform.windows => 'Windows',
        ProjectPlatform.android => 'Android',
        ProjectPlatform.web => 'Web',
        ProjectPlatform.linux => 'Linux',
        ProjectPlatform.macos => 'macOS',
        ProjectPlatform.ios => 'iOS',
      };

  static ProjectPlatform? fromId(String value) {
    for (final platform in ProjectPlatform.values) {
      if (platform.id == value.trim().toLowerCase()) return platform;
    }
    return null;
  }
}
