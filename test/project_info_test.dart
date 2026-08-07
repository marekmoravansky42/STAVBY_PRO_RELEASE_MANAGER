import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/models/project_info.dart';

void main() {
  group('ProjectInfo.releaseBuild', () {
    test('načíta MOBILE_UI build z názvu priečinka', () {
      const project = ProjectInfo(
        projectName: 'stavby_pro',
        projectPath: r'C:\\6\\STAVBY_PRO_3.5.10_DEV_MOBILE_UI_83',
        version: '3.5.10',
        build: 2026071983,
      );

      expect(project.releaseBuild, 83);
    });

    test('použije technický build pri bežnom Flutter projekte', () {
      const project = ProjectInfo(
        projectName: 'demo',
        projectPath: r'C:\\projekty\\demo',
        version: '1.0.0',
        build: 7,
      );

      expect(project.releaseBuild, 7);
    });
  });
}
