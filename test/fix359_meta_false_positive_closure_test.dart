import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX359 FIX355 guard ignores negative historical contains assertions', () {
    final source=File('test/fix355_dev015_identity_tests_generalized_test.dart').readAsStringSync();
    expect(source, contains(r'''expect\([^\n]*,\s*contains\(['"]RC1 DEV015 FIX\d+['"]\)\s*\)'''));
  });

  test('FIX359 canonical identity is Build333 DEV015 FIX359', () {
    final identity=File('lib/app/app_version.dart').readAsStringSync();
    expect(identity, contains('static const int build = 333;'));
    expect(identity, contains('RC1 DEV015 FIX'));
  });
}
