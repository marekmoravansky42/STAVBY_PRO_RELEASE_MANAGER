import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('One Click Release includes Android APK release build', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf('Future<void> _runOneClickReleaseComplete()');
    final end = source.indexOf('Future<bool> _applyReleaseRecipe', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final block = source.substring(start, end);
    expect(block, contains("<String>['build', 'apk', '--release']"));
    expect(block, contains("Android Release APK build"));
  });
}
