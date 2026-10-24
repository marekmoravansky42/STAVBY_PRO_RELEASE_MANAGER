import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('One Click Release uses Android APK from the platform build', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf('Future<void> _runOneClickReleaseComplete()');
    final end = source.indexOf('Future<bool> _applyReleaseRecipe', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final block = source.substring(start, end);
    expect(block, contains('Používam Android Release APK vytvorené '));
    expect(block, contains('final apkFile = await _findReleaseApk(workspace);'));
    expect(block, isNot(contains('Spúšťam Android Release APK build...')));
  });
}
