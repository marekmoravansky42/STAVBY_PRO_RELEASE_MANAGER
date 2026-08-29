import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX250 CMD failure dialog uses valid ProjectInfo projectName getter', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains("projectName: _project?.projectName ?? 'Projekt',"));
    expect(source, isNot(contains("projectName: _project?.name ?? 'Projekt',")));
  });
}
