import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX367 FIX366 source assertion treats requestedTag as literal text', () {
    final source = File('test/fix366_existing_final_tag_resume_test.dart').readAsStringSync();
    expect(source, contains("contains(r'FINAL tag"));
    expect(source, contains('requestedTag'));
  });

  test('FIX367 identity remains Build333 DEV015', () {
    final identity = File('lib/app/app_version.dart').readAsStringSync();
    expect(identity, contains('static const int build = 333;'));
    expect(identity, contains('RC1 DEV015 FIX'));
  });
}
