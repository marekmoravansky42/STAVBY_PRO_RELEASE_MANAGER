import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
void main() {
  late String source;
  setUpAll(() => source = File('lib/main.dart').readAsStringSync());
  test('intentional fallback helpers stay documented', () {
    expect(source, contains('Legacy Git commit dialog retained as a fallback'));
    expect(source, contains('Legacy standalone tag dialog retained as a fallback'));
    expect(source, contains('Internal verifier retained intentionally for automatic Release Integrity'));
  });
  test('release workflow remains protected', () {
    expect(source, anyOf(contains("releaseStage: 'DEV'"), contains('releaseStage: releaseStage')));
    expect(source, contains('releaseStage: selected,'));
    expect(source, contains('ONE CLICK RELEASE EXPORT GATE OK:'));
  });
}
