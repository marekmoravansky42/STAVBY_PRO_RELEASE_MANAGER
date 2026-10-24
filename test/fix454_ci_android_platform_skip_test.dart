import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/core/project_workspace/project_platform.dart';
import 'package:stavby_pro_release_manager/core/project_workspace/project_workspace.dart';
import 'package:stavby_pro_release_manager/core/release_pipeline/pipeline_step.dart';
import 'package:stavby_pro_release_manager/features/release_pipeline_designer/release_pipeline_execution_controller.dart';

void main() {
  const windowsOnlyWorkspace = ProjectWorkspace(
    rootPath: r'C:\SP\Release_Manager',
    projectName: 'stavby_pro_release_manager',
    platforms: <ProjectPlatform>{ProjectPlatform.windows},
  );

  test(
      'FIX454 skips Android build actions when the project has no Android platform',
      () {
    for (final action in <String>['android_apk', 'android_aab']) {
      final reason =
          ReleasePipelineExecutionController.unsupportedPlatformReason(
        PipelineStep(id: action, title: action, action: action),
        windowsOnlyWorkspace,
      );
      expect(reason,
          'Platforma Android nie je v cieľovom projekte. Krok bol bezpečne preskočený.');
    }
  });

  test('FIX454 still allows Android builds for an Android workspace', () {
    const androidWorkspace = ProjectWorkspace(
      rootPath: r'C:\SP\STAVBY_PRO',
      projectName: 'stavby_pro',
      platforms: <ProjectPlatform>{
        ProjectPlatform.windows,
        ProjectPlatform.android
      },
    );
    expect(
      ReleasePipelineExecutionController.unsupportedPlatformReason(
        const PipelineStep(id: 'apk', title: 'APK', action: 'android_apk'),
        androidWorkspace,
      ),
      isNull,
    );
  });
}
