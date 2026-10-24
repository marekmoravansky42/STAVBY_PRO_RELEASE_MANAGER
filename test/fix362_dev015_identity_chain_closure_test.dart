import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX362 recent DEV015 tests do not positively pin an exact current FIX', () {
    final files = Directory('test')
        .listSync()
        .whereType<File>()
        .where((f) => RegExp(r'fix3(5[0-9]|6[0-2]).*_test\.dart$').hasMatch(f.path));
    final positivePin = RegExp(
      r"expect\([^\n]+,\s*contains\('RC1 DEV015 FIX\d+'\)\);",
    );
    for (final file in files) {
      expect(file.readAsStringSync(), isNot(matches(positivePin)),
          reason: file.path);
    }
  });

  test('FIX362 canonical identity stays Build333 DEV015 with numeric FIX', () {
    final identity = File('lib/app/app_version.dart').readAsStringSync();
    expect(identity, contains('static const int build = 333;'));
    expect(identity, matches(RegExp(r"static const String stage = 'RC1 DEV015 FIX\d+';")));
  });
}
