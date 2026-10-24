import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX423 release history uses a compact item layout', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf('Widget _buildReleaseHistoryPage()');
    final end = source.indexOf('Widget _buildReleaseComparisonCard()', start);
    final historyPage = source.substring(start, end);

    expect(historyPage, contains('padding: const EdgeInsets.only(bottom: 5)'));
    expect(
      historyPage,
      contains(
        RegExp(
          r'padding:\s*const\s+EdgeInsets\.symmetric\('
          r'\s*horizontal:\s*12,\s*vertical:\s*8\s*\)',
        ),
      ),
    );
    expect(historyPage, contains('message: item.path'));
    expect(historyPage,
        isNot(contains('Text(\n                              item.path,')));
  });
}
