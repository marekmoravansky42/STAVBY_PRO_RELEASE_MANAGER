import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX427 Windows runner packages the icon for pinned taskbar entries', () {
    final windowSource = File('windows/runner/win32_window.cpp').readAsStringSync();
    final mainSource = File('windows/runner/main.cpp').readAsStringSync();
    final cmake = File('windows/runner/CMakeLists.txt').readAsStringSync();

    expect(windowSource, contains('MAKEINTRESOURCE(IDI_APP_ICON)'));
    expect(windowSource, contains('WM_SETICON, ICON_BIG'));
    expect(windowSource, contains('WM_SETICON, ICON_SMALL'));
    expect(windowSource, contains('PKEY_AppUserModel_RelaunchIconResource'));
    expect(windowSource, contains('PKEY_AppUserModel_ID'));
    expect(windowSource, contains('app_icon.ico'));
    expect(windowSource, contains('STAVBY.PRO.ReleaseManager'));
    expect(mainSource, isNot(contains('SetCurrentProcessExplicitAppUserModelID')));
    expect(cmake, contains('"shell32.lib"'));
    expect(cmake, contains('copy_if_different'));
    expect(cmake, contains('app_icon.ico'));
  });
}
