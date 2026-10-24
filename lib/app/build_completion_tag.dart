String suggestBuildCompletionTag({
  required ({String version, int build, String stage})? identity,
  required String releaseType,
}) {
  if (identity == null) return '';
  final version = identity.version;
  switch (releaseType) {
    case 'RC':
      return 'v$version-rc1';
    case 'FINAL':
      return 'v$version-final-b${identity.build}';
    case 'FIX':
      return 'v$version-build${identity.build}-fix';
    default:
      return 'v$version-build${identity.build}';
  }
}
