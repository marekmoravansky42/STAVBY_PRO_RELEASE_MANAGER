import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX310 FINAL publication receipt keeps enriched persisted evidence and live status separate', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains("'projectName': project.projectName"));
    expect(source, contains("'sourceFinalTag':"));
    expect(source, contains(r'-final-b${project.releaseBuild}'));
    expect(source, contains("'githubReleaseTag': tagName"));
    expect(source, contains("'apkSha256': _apkSha256"));
    expect(source, contains("'apkSizeBytes': _apkSizeBytes"));
    expect(source, contains('Uložený doklad publikovania:'));
    expect(source, contains('Aktuálny online stav:'));
    expect(source, contains('OVERIŤ PUBLIKOVANIE'));
  });

  test('FIX310 canonical identity remains future FIX compatible inside Build 327 DEV009', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
