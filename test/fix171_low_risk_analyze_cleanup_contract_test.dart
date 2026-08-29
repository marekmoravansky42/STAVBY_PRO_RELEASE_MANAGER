import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('obsolete low-risk analyze warnings stay removed', () {
    final source = File('lib/main.dart').readAsStringSync();

    final exportStart = source.indexOf('Future<File> _createOneClickReleaseZip');
    final exportEnd = source.indexOf('Future<void> _selectFileInExplorer', exportStart);
    final exportBlock = source.substring(exportStart, exportEnd);

    expect(
      exportBlock,
      isNot(contains('final identity = await _readGitBuildIdentity(projectPath);')),
    );
    expect(source, isNot(contains('Widget _dashboardEventRow(')));
    expect(
      source,
      isNot(
        contains(
          'Widget _buildSectionOverviewDashboard() {\n    final apkReady = _apkPath != null;',
        ),
      ),
    );
  });
}
