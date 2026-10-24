import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX302 uses existing release root resolver for publication audit', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('final root = _resolveDashboardIntegrityRoot();'));
    expect(source, isNot(contains('final root = _releaseRootDirectory();')));
    expect(source, contains("event: 'FINAL_PUBLICATION_ONLINE_VERIFIED'"));
  });

  test('FIX302 keeps historical identity without pinning later DEV/FIX', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
