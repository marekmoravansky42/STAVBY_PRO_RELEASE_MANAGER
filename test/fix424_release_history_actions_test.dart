import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX424 release history colors metadata and confirms deletion', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf('Future<void> _deleteReleaseHistoryItem(');
    final end = source.indexOf('Widget _buildReleaseHistoryPage()', start);
    final deletion = source.substring(start, end);
    final pageStart = source.indexOf('Widget _buildReleaseHistoryPage()');
    final pageEnd = source.indexOf('Widget _buildReleaseComparisonCard()', pageStart);
    final page = source.substring(pageStart, pageEnd);

    expect(deletion, contains("title: const Text('Odstrániť vydanie?')"));
    expect(deletion, contains('barrierDismissible: false'));
    expect(deletion, contains('await file.delete()'));
    expect(deletion, contains('await directory.delete(recursive: true)'));
    expect(page, contains("_releaseHistoryPlatformChip(\n                                      'Windows'"));
    expect(page, contains("_releaseHistoryPlatformChip(\n                                      'Android'"));
    expect(page, contains("tooltip: 'Odstrániť release výstup'"));
  });
}
