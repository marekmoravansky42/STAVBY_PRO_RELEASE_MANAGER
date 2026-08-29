import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('One Click export uses pubspec project identity', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf('Future<File> _createOneClickReleaseZip');
    final end = source.indexOf('Future<void> _selectFileInExplorer', start);
    final block = source.substring(start, end);

    expect(
      block,
      contains('final currentProject = await _pubspecService.readProject(projectPath);'),
    );
    expect(block, contains('final projectName = currentProject.projectName'));
    expect(
      block,
      isNot(contains('final projectName = path.basename(projectPath).toUpperCase();')),
    );
  });

  test('One Click export registers unpacked release directory', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf('Future<File> _createOneClickReleaseZip');
    final end = source.indexOf('Future<void> _selectFileInExplorer', start);
    final block = source.substring(start, end);

    expect(block, contains('final registeredReleaseDirectory = Directory('));
    expect(
      block,
      contains('await stagingDirectory.rename(registeredReleaseDirectory.path);'),
    );
    expect(
      block,
      contains('_releaseWizardReleaseDirectory = registeredReleaseDirectory.path;'),
    );
  });
}
