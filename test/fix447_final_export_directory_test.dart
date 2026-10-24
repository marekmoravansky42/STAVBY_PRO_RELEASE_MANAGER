import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('lib/main.dart').readAsStringSync();

  test('FIX447 sends STAVBY PRO FINAL ZIP and APK to a dedicated path', () {
    expect(source, contains('STAVBY PRO – FINAL vydanie'));
    expect(source, contains('_chooseStavbyProFinalReleaseExportDirectory'));
    final start = source.indexOf('String _releaseExportRootForProject(');
    final end = source.indexOf('Future<File> _createOneClickReleaseZip(', start);
    final resolver = source.substring(start, end);
    expect(resolver, contains("releaseStage?.trim().toUpperCase() == 'FINAL'"));
    expect(resolver, contains('_stavbyProFinalReleaseExportDirectory'));
    expect(source, contains("final androidExport = selected == 'FINAL'"));
  });
}