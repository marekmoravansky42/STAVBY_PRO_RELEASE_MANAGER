import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX422 release history finds all release folders and ZIP archives', () {
    final source = File('lib/main.dart').readAsStringSync();
    final loadStart = source.indexOf('Future<void> _loadReleaseHistory() async');
    final loadEnd = source.indexOf('Future<void> _checkProjectReadiness()', loadStart);
    final pageStart = source.indexOf('Widget _buildReleaseHistoryPage()');
    final pageEnd = source.indexOf('Widget _buildReleaseComparisonCard()', pageStart);
    final loadHistory = source.substring(loadStart, loadEnd);
    final releaseHistoryPage = source.substring(pageStart, pageEnd);

    expect(loadHistory, contains('..addAll(items);'));
    expect(loadHistory, isNot(contains('.take(20)')));
    expect(
      releaseHistoryPage,
      contains(r'Nájdené vydania: ${items.length}.'),
    );
    expect(releaseHistoryPage, contains('...items.map((item)'));
    expect(releaseHistoryPage, isNot(contains('items.take(30)')));
    expect(
      source,
      contains("'Export Release win a android'"),
    );
    expect(source, contains("if (entity is File)"));
    expect(source, contains("if (!upper.endsWith('.ZIP')) continue;"));
  });
}
