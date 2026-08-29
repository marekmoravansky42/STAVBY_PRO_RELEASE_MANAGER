import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canonical Release Manager identity is Build 317 FIX267', () {
    final source = File('lib/app/app_version.dart').readAsStringSync();
    expect(source, contains("static const String version = '8.0.0';"));
    expect(source, contains('static const int build = 317;'));
    expect(source, contains("static const String stage = 'RC1 DEV001 FIX267';"));
  });

  test('Plugin Marketplace uses canonical Release Manager version', () {
    final source = File(
      'lib/features/plugin_marketplace/plugin_marketplace_page.dart',
    ).readAsStringSync();
    expect(
      source.split('currentReleaseManagerVersion: ReleaseManagerVersion.version').length - 1,
      2,
    );
    expect(source, isNot(contains("currentReleaseManagerVersion: '6.5.2'")));
  });
}
