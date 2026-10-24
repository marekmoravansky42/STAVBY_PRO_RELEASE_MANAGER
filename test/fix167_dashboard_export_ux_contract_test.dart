import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

int _callEnd(String source, int start) {
  var depth = 0;
  for (var index = start; index < source.length; index++) {
    final character = source[index];
    if (character == '(') depth++;
    if (character == ')' && --depth == 0) return index + 1;
  }
  return -1;
}

void main() {
  late String source;
  setUpAll(() => source = File('lib/main.dart').readAsStringSync());

  test('Fast Dev Build does not auto-open Explorer after ZIP export', () {
    final marker = source.indexOf(
      '// FIX167: po FAST/FULL DEV builde Prieskumník neotvárame',
    );
    expect(marker, greaterThanOrEqualTo(0));

    final before = source.substring(
      source.lastIndexOf("if (exportReleaseZip)", marker),
      marker,
    );
    expect(
      before,
      isNot(contains('await _selectFileInExplorer(releaseZipFile.path);')),
    );
  });

  test('Project Information contains Last Export ZIP', () {
    final exportLabel = source.indexOf("label: 'Posledný export ZIP'");
    final exportRowStart =
        source.lastIndexOf('DashboardProjectInfoRow(', exportLabel);
    expect(exportRowStart, greaterThanOrEqualTo(0));
    final exportRowEnd = _callEnd(source, exportRowStart);
    expect(exportRowEnd, greaterThan(exportRowStart));
    final exportRow = source.substring(exportRowStart, exportRowEnd);

    expect(exportRow,
        contains('path.basename(_dashboardLastVerifiedExportZipPath!)'));
    expect(
      RegExp(
        r'onTap:\s*\(\)\s*=>\s*_selectFileInExplorer\(\s*_dashboardLastVerifiedExportZipPath!\s*,?\s*\)',
      ).hasMatch(exportRow),
      isTrue,
      reason: 'Kliknutie musí odovzdať ten istý overený ZIP do Prieskumníka.',
    );
  });

  test('Last build no longer renders full export path', () {
    final start = source.indexOf("title: 'Posledný build'");
    final end = source.indexOf('return Column(', start);
    final block = source.substring(start, end);
    expect(block, isNot(contains('_dashboardLastVerifiedExportZipPath')));
  });
}
