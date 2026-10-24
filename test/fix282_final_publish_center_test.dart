import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX282 FINAL release opens integrated FINAL Publish Center', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('FINAL Publish Center'));
    expect(source, contains("selected == 'FINAL' && finalReleaseZip != null"));
    expect(source, contains('NOVINKY / OPRAVY + GIT'));
    expect(source, contains('PUBLIKOVAŤ FINAL'));
    expect(source, contains('_publishToGitHub()'));
    expect(source, contains("setState(() => _selectedPage = 5)"));
    expect(source, contains('PUBLIKOVAŤ CELÉ VYDANIE'));
  });

  test('FIX282 identity starts Build 321 DEV003 without pinning future FIX tests', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, contains('static const int build = '));
    expect(version, contains("static const String stage = 'RC1 DEV"));
    expect(pubspec, contains('version: 8.0.0+'));
    final buildMatch = RegExp(r'static const int build = (\d+);').firstMatch(version);
    expect(buildMatch, isNotNull);
    expect(pubspec, contains('+${buildMatch!.group(1)}'));
  });
}
