import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX360 historical FIX358 identity no longer pins exact FIX358', () {
    final source = File('test/fix358_dev015_meta_test_closure_test.dart').readAsStringSync();
    expect(source, contains('RC1 DEV015 FIX'));
    expect(source, isNot(contains('RC1 DEV015 FIX358')));
  });

  test('FIX360 canonical identity is Build333 DEV015 FIX360', () {
    final identity = File('lib/app/app_version.dart').readAsStringSync();
    expect(identity, contains('static const int build = 333;'));
    expect(identity, matches(RegExp(r"static const String stage = 'RC1 DEV015 FIX\d+';")));
  });
}
