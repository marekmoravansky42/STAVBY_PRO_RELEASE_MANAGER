import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX250 Android APK One Click step uses cmd.exe on Windows', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains("step.args[1] == 'apk'"));
    expect(source, contains("step.args[2] == '--release'"));
    expect(source, contains('isAndroidApkStep && Platform.isWindows'));
    expect(source, contains('await _runWorkspaceCmdFlutterStep('));
    expect(source, contains("'cmd.exe'"));
    expect(source, contains("<String>['/d', '/s', '/c', commandText]"));
  });

  test('FIX250 other One Click steps keep existing Flutter runner', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('await _runWorkspaceFlutterStep('));
  });
}
