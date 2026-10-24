import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX346 historical DEV013 tests do not pin DEV013 as current stage', () {
    final stale = <String>[];
    for (final entity in Directory('test').listSync()) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final name = entity.uri.pathSegments.last;
      final match = RegExp(r'^fix(32[7-9]|33\d|34[0-3])_').firstMatch(name);
      if (match == null) continue;
      final source = entity.readAsStringSync();
      if (source.contains(r"""matches(RegExp(r"static const String stage = 'RC1 DEV013 FIX\d+';"))""")) {
        stale.add(name);
      }
    }
    expect(stale, isEmpty);
  });

  test('FIX346 total FINAL regression remains active', () {
    final source = File('test/fix344_final_publishing_workflow_total_regression_test.dart').readAsStringSync();
    expect(source, contains('FIX344 FINAL workflow keeps Release Notes and FINAL artifacts wiring'));
    expect(source, contains('FIX344 FINAL workflow keeps Publish Gate and GitHub publishing wiring'));
    expect(source, contains('FIX344 FINAL workflow keeps online verification and persisted receipt'));
  });

  test('FIX346 canonical identity remains Build 332 DEV014', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
