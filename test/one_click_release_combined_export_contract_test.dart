import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release export contains Windows and Android staging support', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf(
      'Future<File> _createOneClickReleaseZip(',
    );
    final end = source.indexOf(
      'Future<void> _selectFileInExplorer',
      start,
    );
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final block = source.substring(start, end);
    expect(block, contains("path.join(stagingDirectory.path, 'Windows')"));
    expect(block, contains("path.join(stagingDirectory.path, 'Android')"));
    expect(block, contains('_WINDOWS_ANDROID_RELEASE'));
  });
}
