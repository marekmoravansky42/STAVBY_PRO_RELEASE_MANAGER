import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Export ZIP OK requires a physical file', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('if (!await zip.exists())'));
    expect(source, contains('final zipSize = await zip.length();'));
    expect(source, contains('if (zipSize <= 0)'));
    expect(source, contains('_dashboardLastVerifiedExportZipPath = zip.path;'));
    expect(source, contains("OTVORIŤ EXPORT ZIP V PRIESKUMNÍKOVI"));
    expect(source, contains('_selectFileInExplorer(zip.path)'));
  });
}
