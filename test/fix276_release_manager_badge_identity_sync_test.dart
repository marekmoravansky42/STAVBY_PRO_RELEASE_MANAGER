import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX276 Release Manager badge identity follows current FIX', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, contains('static const int build = '));
    expect(version, contains("static const String stage = 'RC1 DEV"));
  });
}
