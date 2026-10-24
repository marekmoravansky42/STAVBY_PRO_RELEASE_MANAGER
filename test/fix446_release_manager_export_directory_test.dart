import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('lib/main.dart').readAsStringSync();

  test('FIX446 routes Release Manager exports to its own configured directory', () {
    final start = source.indexOf('bool _isReleaseManagerProject(');
    final end = source.indexOf('Future<File> _createOneClickReleaseZip(', start);
    final helper = source.substring(start, end);
    expect(helper, contains("STAVBY_PRO_RELEASE_MANAGER"));
    expect(helper, contains('_managerUpdateDownloadDirectory'));
    expect(helper, contains('_windowsReleaseExportDirectory'));

    final zipStart = source.indexOf('Future<File> _createOneClickReleaseZip(');
    final zipEnd = source.indexOf('Future<void> _refreshDistributionCenterFromDisk', zipStart);
    expect(source.substring(zipStart, zipEnd), contains('_releaseExportRootForProject('));
    expect(source, contains('final releaseDestination = _releaseExportRootForProject('));
    expect(source, contains('addRoot(_managerUpdateDownloadDirectory);'));
  });
}