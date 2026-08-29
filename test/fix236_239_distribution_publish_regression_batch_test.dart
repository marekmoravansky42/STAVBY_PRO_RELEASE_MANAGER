import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  setUpAll(() => source = File('lib/main.dart').readAsStringSync());

  test('FIX236 Distribution Center contract remains present', () {
    expect(source, contains('Distribution Center'));
  });

  test('FIX237 Publish Gate contract remains present', () {
    expect(source, contains('Publish Gate'));
  });

  test('FIX238 platform detection contract remains present', () {
    expect(source, contains('platform detection'));
  });

  test('FIX239 Windows executable detection contract remains present', () {
    expect(source, contains('Windows EXE'));
  });

  test('FIX236-239 keeps identity in the canonical version source', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, contains('abstract final class ReleaseManagerVersion'));
    expect(version, contains('static const int build = '));
    expect(version, contains('static const String stage = '));
  });
}
