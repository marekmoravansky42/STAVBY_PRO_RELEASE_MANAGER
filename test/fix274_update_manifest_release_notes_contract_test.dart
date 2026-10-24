import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX274 update manifest publishes notes understood by STAVBY PRO', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains("'channel': 'final'"));
    expect(source, contains("'mandatory': false"));
    expect(source, contains("'notes': notes"));
    expect(source, contains('final notes = <String>['));
    expect(source, contains('...news'));
    expect(source, contains('...fixes'));
  });

  test('FIX274 Release Manager identity is Build 320 DEV002', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, contains('static const int build = '));
    expect(version, contains("static const String stage = 'RC1 DEV"));
    expect(pubspec, contains('version: 8.0.0+'));
  });
}
