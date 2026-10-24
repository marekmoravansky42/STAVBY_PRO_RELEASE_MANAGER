import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX304 FIX303 regression assertion preserves regex backslash literally', () {
    final source = File('test/fix303_stale_fix300_identity_contract_refresh_test.dart').readAsStringSync();
    expect(source, contains(r'contains(r"static const int build = \d+;")'));
  });

  test('FIX304 keeps historical identity without pinning later DEV/FIX', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
