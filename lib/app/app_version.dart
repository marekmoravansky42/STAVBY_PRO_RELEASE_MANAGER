abstract final class ReleaseManagerVersion {
  static const String version = '8.0.0';
  static const int build = 262;
  static const String channel = 'RC1';
  static const String stage = 'RC1 DEV001 FIX145';

  static const String label = '$version $channel Build $build $stage';
  static const String badge = 'v$version $channel • Build $build • $stage';
  static const String compact = '$version $channel\nBUILD $build $stage';
}
