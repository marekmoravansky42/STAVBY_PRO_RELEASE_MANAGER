import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FAST/FULL build verifies export ZIP without auto-opening Explorer', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('ONE CLICK BUILD EXPORT OVERENÝ:'));
    expect(
      source,
      isNot(contains('await _selectFileInExplorer(releaseZipFile.path);')),
    );
    expect(source, contains('Export Release ZIP – presná cesta:'));
    expect(source, contains('OTVORIŤ EXPORT ZIP V PRIESKUMNÍKOVI'));
    expect(source, contains('_dashboardLastVerifiedExportZipPath'));
    expect(source, contains("'Posledný export ZIP'"));
  });
}
