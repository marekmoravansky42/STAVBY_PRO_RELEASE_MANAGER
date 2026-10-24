import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX298 FINAL Publish Center can create and verify FINAL Git archive', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('_archiveFinalSourceFromPublishCenter()'));
    expect(source, contains("finalPublishCenterArchiveGitButton"));
    expect(source, contains("label: const Text('ULOŽIŤ FINAL DO GITU')"));
    expect(source, contains("'tag'"));
    expect(source, contains("'-a'"));
    expect(source, contains("'push', 'origin', tag"));
    expect(source, contains('final verified = await _verifyFinalSourceArchive();'));
  });

  test('FIX298 canonical identity remains valid after later builds', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
