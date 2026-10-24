import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX361 historical FIX359 identity no longer pins exact FIX359', () {
    final source = File('test/fix359_meta_false_positive_closure_test.dart').readAsStringSync();
    expect(source, contains('RC1 DEV015 FIX'));
    expect(source, isNot(contains('RC1 DEV015 FIX359')));
  });

  test('FIX361 canonical identity stays Build333 DEV015 with numeric FIX', () {
    final identity = File('lib/app/app_version.dart').readAsStringSync();
    expect(identity, contains('static const int build = 333;'));
    expect(identity, matches(RegExp(r"static const String stage = 'RC1 DEV015 FIX\d+';")));
  });
}
