import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX297 historical publish gate tests follow verified Git archive contract', () {
    final fix285 = File('test/fix285_final_publish_git_source_gate_test.dart').readAsStringSync();
    final fix295 = File('test/fix295_final_git_archive_verification_test.dart').readAsStringSync();
    expect(fix285, isNot(contains('_gitWorkspaceStatus?.isClean == true')));
    expect(fix285, contains('_verifyFinalSourceArchive()'));
    expect(fix295, isNot(contains("RC1 DEV005 FIX295';")));
  });

  test('FIX297 canonical identity remains valid after later builds', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
