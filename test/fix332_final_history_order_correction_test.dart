import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX332 FINAL history is reversed exactly once and displayed newest first', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(
      source,
      contains(
        'Map<String, dynamic>.from(item)',
      ),
    );
    expect(source, contains('final displayHistory = verifiedOnly'));
    expect(
      source,
      isNot(contains('history.reversed.toList(growable: false)')),
    );
    expect(source, contains('final item = displayHistory[index];'));
  });

  test('FIX332 canonical identity remains Build 331 DEV013', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
