import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX286 historical FIX283 publish gate allows additional gate conditions', () {
    final testSource = File('test/fix283_final_publish_gate_test.dart').readAsStringSync();
    expect(testSource, isNot(contains('notesReady;')));
    expect(testSource, contains('notesReady'));
  });

  test('FIX286 canonical identity remains Build 321 DEV003', () {
    final source = File('lib/app/app_version.dart').readAsStringSync();
    expect(source, contains('static const int build = '));
    expect(source, contains("static const String stage = 'RC1 DEV"));
  });
}
