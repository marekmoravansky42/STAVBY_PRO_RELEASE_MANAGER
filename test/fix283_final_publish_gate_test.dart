import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX283 FINAL Publish Center gates publishing on complete FINAL outputs', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('final publishReady ='));
    expect(source, contains('releaseZip.existsSync()'));
    expect(source, contains('apkReady'));
    expect(source, contains('integrityReady'));
    expect(source, contains('notesReady'));
    expect(source, contains("Publish Gate: \${publishReady ? 'POVOLENÉ' : 'BLOKOVANÉ – dokonči chýbajúce kroky'}"));
    expect(source, contains('onPressed: publishReady'));
    expect(source, contains('await _publishToGitHub()'));
  });

  test('FIX283 canonical identity is Build 321 DEV003', () {
    final source = File('lib/app/app_version.dart').readAsStringSync();
    expect(source, contains('static const int build = '));
    expect(source, contains('RC1 DEV'));
  });
}
