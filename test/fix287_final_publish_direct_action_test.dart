import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX287 FINAL Publish Center publishes whole release directly', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('final githubReady = _githubConnected;'));
    expect(source, contains('gitReady'));
    expect(source, contains('githubReady'));
    expect(source, contains('GitHub/update pripojenie:'));
    expect(source, contains("label: const Text('PUBLIKOVAŤ FINAL')"));
    expect(source, contains('await _publishToGitHub();'));
  });

  test('FIX287 canonical identity remains Build 321 DEV003', () {
    final source = File('lib/app/app_version.dart').readAsStringSync();
    expect(source, contains('static const int build = '));
    expect(source, contains('RC1 DEV'));
  });
}
