import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  setUpAll(() => source = File('lib/main.dart').readAsStringSync());

  test('FIX232 Local Agent startup recovery contract remains present', () {
    expect(source, contains('Local Agent startup'));
  });

  test('FIX233 Release Integrity startup restore contract remains present', () {
    expect(source, contains('RELEASE INTEGRITY STARTUP RESTORE'));
  });

  test('FIX234 Workspace Sync keeps One Click Build reset contract', () {
    expect(source, contains('One Click Build bol po synchronizácii resetovaný'));
  });

  test('FIX235 Workspace Sync SAFE MODE contract remains present', () {
    expect(source, contains('Workspace Sync SAFE MODE'));
  });

  test('FIX232-235 keeps identity in the canonical version source', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, contains('abstract final class ReleaseManagerVersion'));
    expect(version, contains('static const int build = '));
    expect(version, contains('static const String stage = '));
  });
}
