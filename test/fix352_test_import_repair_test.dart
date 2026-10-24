import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX352 FIX351 regression test uses flutter_test', () {
    final source = File('test/fix351_final_completion_retry_and_tag_repair_test.dart')
        .readAsStringSync();
    expect(source, contains("package:flutter_test/flutter_test.dart"));
  });

  test('FIX352 canonical identity remains Build333 DEV015', () {
    final identity = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(identity, contains('static const int build = 333;'));
    expect(identity, contains("RC1 DEV015 FIX"));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+333\b')));
  });
}
