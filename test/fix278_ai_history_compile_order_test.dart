import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX278 fallback description is declared before history loader', () {
    final source = File('lib/main.dart').readAsStringSync();
    final fallback = source.indexOf('String suggestedDescription()');
    final history = source.indexOf('Future<String> suggestedDescriptionFromHistory() async');
    expect(fallback, greaterThanOrEqualTo(0));
    expect(history, greaterThan(fallback));
  });

  test('FIX278 canonical badge is current', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, contains("static const int build = "));
    expect(version, contains("static const String stage = 'RC1 DEV"));
  });
}
