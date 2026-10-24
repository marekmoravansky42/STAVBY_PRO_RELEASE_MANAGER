import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Build Completion export reads release type from completion data', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(
      source,
      contains("completionReleaseType"),
    );
    expect(source, contains('releaseStage: completionReleaseType,'));
    expect(source, isNot(contains('releaseStage: releaseType,')));
  });

  test('Fast Dev Build still explicitly exports DEV', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(
      source,
      anyOf(contains("releaseStage: 'DEV'"), contains('releaseStage: releaseStage')),
    );
  });
}
