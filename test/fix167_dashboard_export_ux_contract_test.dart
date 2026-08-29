import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
    expect(source, contains("'Posledný export ZIP'"));
    expect(
      source,
      contains('path.basename(_dashboardLastVerifiedExportZipPath!)'),
    );
    expect(
      source,
      contains('onTap: () => _selectFileInExplorer(\n                  _dashboardLastVerifiedExportZipPath!'),
    );
  });

  test('Last build no longer renders full export path', () {
    final start = source.indexOf("title: 'Posledný build'");
    final end = source.indexOf('return Column(', start);
    final block = source.substring(start, end);
    expect(block, isNot(contains('_dashboardLastVerifiedExportZipPath')));
  });
}
