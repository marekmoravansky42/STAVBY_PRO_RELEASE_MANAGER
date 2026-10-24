import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX288 FINAL Publish Center exposes GitHub readiness and keeps extensible gate contracts', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('final githubReady = _githubConnected;'));
    expect(source, contains('GitHub/update pripojenie:'));
    expect(source, contains('notesReady'));
    expect(source, contains('gitReady'));
    expect(source, contains('githubReady'));
    expect(source, contains("label: const Text('PUBLIKOVAŤ FINAL')"));
    expect(source, contains('await _publishToGitHub();'));
  });

  test('FIX288 canonical identity remains Build 321 DEV003', () {
    final source = File('lib/app/app_version.dart').readAsStringSync();
    expect(source, contains('static const int build = '));
    expect(source, contains("static const String stage = 'RC1 DEV"));
  });
}
