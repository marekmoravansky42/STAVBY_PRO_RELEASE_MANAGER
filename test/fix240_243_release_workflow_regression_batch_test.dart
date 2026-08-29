import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  setUpAll(() => source = File('lib/main.dart').readAsStringSync());

  test('FIX240 flutter analyze workflow contract remains present', () {
    expect(source, contains('flutter analyze'));
  });

  test('FIX241 flutter test workflow contract remains present', () {
    expect(source, contains('flutter test'));
  });

  test('FIX242 Windows release build workflow contract remains present', () {
    expect(source, contains('flutter build windows'));
  });

  test('FIX243 clean/full-build recovery contract remains present', () {
    expect(source, contains('flutter clean'));
  });

  test('FIX240-243 keeps identity in the canonical version source', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, contains('abstract final class ReleaseManagerVersion'));
    expect(version, contains('static const int build = '));
    expect(version, contains('static const String stage = '));
  });
}
