import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX366 retry does not create another commit when FINAL tag exists', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains(r'FINAL tag $requestedTag už existuje'));
    expect(source, contains('pri obnove dokončenia nevytváram ďalší commit'));
  });

  test('FIX366 accepts existing FINAL tag only when it is in current branch history', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('merge-base'));
    expect(source, contains('--is-ancestor'));
    expect(source, contains('existujúci FINAL tag sa zachová'));
    expect(source, contains('FINAL vydanie sa neprepíše'));
  });

  test('FIX366 identity remains Build333 DEV015', () {
    final identity = File('lib/app/app_version.dart').readAsStringSync();
    expect(identity, contains('static const int build = 333;'));
    expect(identity, contains('RC1 DEV015 FIX'));
  });
}
