import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
void main() {
  test('FIX370 identity remains Build333 DEV015', () {
    final identity = File('lib/app/app_version.dart').readAsStringSync();
    expect(identity, contains('static const int build = 333;'));
    expect(identity, contains("static const String stage = 'RC1 DEV015 FIX"));
  });
}
