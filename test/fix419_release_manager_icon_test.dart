import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX419 Windows runner uses the new multi-size Release Manager icon', () {
    final icon = File('windows/runner/resources/app_icon.ico');
    final preview = File('windows/runner/resources/app_icon_preview.png');
    final runnerResource = File('windows/runner/Runner.rc').readAsStringSync();

    expect(icon.existsSync(), isTrue);
    expect(icon.lengthSync(), greaterThan(10000));
    expect(preview.existsSync(), isTrue);
    expect(preview.lengthSync(), greaterThan(10000));
    expect(runnerResource, contains(r'IDI_APP_ICON ICON "resources\\app_icon.ico"'));
  });
}
