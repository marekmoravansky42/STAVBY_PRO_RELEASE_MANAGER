import 'pipeline_step.dart';
import 'pipeline_template.dart';

abstract final class DefaultPipelineTemplates {
  static const PipelineStep clean = PipelineStep(
    id: 'flutter_clean',
    title: 'Flutter clean',
    action: 'flutter_clean',
  );
  static const PipelineStep pubGet = PipelineStep(
    id: 'flutter_pub_get',
    title: 'Flutter pub get',
    action: 'flutter_pub_get',
  );
  static const PipelineStep test = PipelineStep(
    id: 'flutter_test',
    title: 'Flutter test',
    action: 'flutter_test',
  );
  static const PipelineStep analyze = PipelineStep(
    id: 'flutter_analyze',
    title: 'Flutter analyze',
    action: 'flutter_analyze',
  );
  static const PipelineStep windowsBuild = PipelineStep(
    id: 'windows_build',
    title: 'Windows build',
    action: 'windows_build',
    requiredPlatforms: <String>['windows'],
  );
  static const PipelineStep androidApk = PipelineStep(
    id: 'android_apk',
    title: 'Android APK build',
    action: 'android_apk',
    requiredPlatforms: <String>['android'],
  );
  static const PipelineStep androidAab = PipelineStep(
    id: 'android_aab',
    title: 'Android AAB build',
    action: 'android_aab',
    requiredPlatforms: <String>['android'],
  );
  static const PipelineStep diagnostics = PipelineStep(
    id: 'diagnostics_export',
    title: 'Diagnostický report',
    action: 'diagnostics_export',
  );
  static const PipelineStep gitSync = PipelineStep(
    id: 'git_sync',
    title: 'Git synchronizácia',
    action: 'git_sync',
  );

  static const PipelineTemplate fullRelease = PipelineTemplate(
    id: 'full_release',
    name: 'Full Release',
    description: 'Kompletný Windows a Android release proces.',
    isDefault: true,
    steps: <PipelineStep>[clean, pubGet, analyze, test, windowsBuild, androidApk, androidAab, diagnostics],
  );
  static const PipelineTemplate windowsRelease = PipelineTemplate(
    id: 'windows_release',
    name: 'Windows Release',
    steps: <PipelineStep>[clean, pubGet, analyze, test, windowsBuild, diagnostics],
  );
  static const PipelineTemplate androidRelease = PipelineTemplate(
    id: 'android_release',
    name: 'Android Release',
    steps: <PipelineStep>[clean, pubGet, analyze, test, androidApk, androidAab, diagnostics],
  );
  static const PipelineTemplate diagnosticsOnly = PipelineTemplate(
    id: 'diagnostics_only',
    name: 'Diagnostics',
    steps: <PipelineStep>[diagnostics],
  );
  static const PipelineTemplate gitSyncOnly = PipelineTemplate(
    id: 'git_sync_only',
    name: 'Git Sync',
    steps: <PipelineStep>[gitSync],
  );

  static const List<PipelineTemplate> all = <PipelineTemplate>[
    fullRelease,
    windowsRelease,
    androidRelease,
    diagnosticsOnly,
    gitSyncOnly,
  ];
}
