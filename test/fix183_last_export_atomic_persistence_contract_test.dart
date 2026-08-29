import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File('lib/main.dart').readAsStringSync();
  });

  test('last export metadata is written through a temporary file', () {
    expect(source, contains("final tempFile = File('\${file.path}.tmp');"));
    expect(source, contains('await tempFile.writeAsString('));
    expect(source, contains('flush: true'));
  });

  test('completed temporary metadata replaces the canonical state file', () {
    expect(source, contains('await file.delete();'));
    expect(source, contains('await tempFile.rename(file.path);'));
  });
}
