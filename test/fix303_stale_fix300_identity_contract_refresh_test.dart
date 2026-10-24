import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX303 historical FIX300 identity no longer pins Build 325 DEV007', () {
    final source = File('test/fix300_final_online_publish_verification_test.dart').readAsStringSync();
    expect(source, isNot(contains("static const int build = 325;")));
    expect(source, isNot(contains("version: 8.0.0+325")));
    expect(source, contains(r"static const int build = \d+;"));
  });

  test('FIX303 keeps historical identity without pinning later DEV/FIX', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
