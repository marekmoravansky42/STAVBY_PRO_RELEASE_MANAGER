import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX295 FINAL Publish Center verifies source archive instead of trusting clean workspace', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('_verifyFinalSourceArchive()'));
    expect(source, contains("'rev-list', '-n', '1', tag"));
    expect(source, contains("'ls-remote'"));
    expect(source, contains("'--exit-code'"));
    expect(source, contains("'--tags'"));
    expect(source, contains("'refs/tags/\$tag^{}'"));
    expect(source, contains("'rev-parse', '@{u}'"));
    expect(source, contains('gitArchive.localTag'));
    expect(source, contains('gitArchive.remoteTag'));
    expect(source, contains('gitArchive.branchPushed'));
    expect(source, contains('gitArchive.tagPointsToHead'));
    expect(source, contains('gitArchive.remoteTagMatchesHead'));
    expect(source, contains('FINAL source tag:'));
    expect(source, contains('Push vetvy:'));
    expect(source, contains('Push FINAL tagu:'));
  });

  test('FIX295 canonical identity remains valid after later builds', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
