import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX353 historical FIX350 and FIX351 allow later FIX in DEV015', () {
    final fix350 = File('test/fix350_final_publish_center_reentry_test.dart').readAsStringSync();
    final fix351 = File('test/fix351_final_completion_retry_and_tag_repair_test.dart').readAsStringSync();

    expect(fix350, contains("static const String stage = 'RC1 DEV015 FIX"));
    expect(fix351, contains("static const String stage = 'RC1 DEV015 FIX"));
    expect(fix350, isNot(contains("RC1 DEV015 FIX';")));
    expect(fix351, isNot(contains("RC1 DEV015 FIX';")));
  });

  test('FIX353 canonical identity remains Build 333 DEV015', () {
    final identity = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(identity, contains('static const int build = 333;'));
    expect(identity, matches(RegExp(r"static const String stage = 'RC1 DEV015 FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+333\b')));
  });
}
