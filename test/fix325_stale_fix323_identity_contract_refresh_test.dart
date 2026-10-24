import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX325 historical FIX323 closure no longer pins exact current FIX', () {
    final historical = File(
      'test/fix323_build330_dev012_final_publication_closure_test.dart',
    ).readAsStringSync();
    final version = File('lib/app/app_version.dart').readAsStringSync();

    expect(
      historical,
      isNot(contains(
        'expect(version, contains("static const String stage = \'RC1 DEV012 FIX323\';"));',
      )),
    );
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
  });
}
