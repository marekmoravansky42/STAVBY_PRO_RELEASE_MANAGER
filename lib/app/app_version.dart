abstract final class ReleaseManagerVersion {
  static const String version = '8.0.0';
  static const int build = 257;
  static const String channel = 'RC1 FIX002';
  static const String stage = 'LOCAL GIT REMOTE FALLBACK + SNAPSHOT';

  static const String label = '$version $channel Build $build $stage';
  static const String badge = 'v$version $channel • Build $build • $stage';
  static const String compact = '$version $channel\nBUILD $build $stage';
}
