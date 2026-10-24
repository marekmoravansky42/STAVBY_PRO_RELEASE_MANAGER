import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('lib/main.dart').readAsStringSync();

  test(
      'FIX418 dashboard Flutter Test failure keeps toast and opens detailed dialog',
      () {
    expect(source,
        contains("_showError('\$title zlyhal. Návratový kód: \$code.')"));
    expect(source, contains("if (operation == 'test')"));
    expect(source, contains('_showFlutterTestFailureDialog('));
    expect(source, contains("Text('Flutter Test zlyhal')"));
    expect(source, contains('_flutterTestFailureHighlights(output)'));
  });

  test('FIX418 dialog scrolls output and exposes complete report actions', () {
    expect(source, contains('SingleChildScrollView('));
    expect(source, contains("'OTVORIŤ ÚPLNÝ REPORT'"));
    expect(source, contains("'SKOPÍROVAŤ ÚPLNÝ LOG'"));
    expect(source, contains('_saveDiagnosticReport('));
  });
}
