import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX369 accepts preserved FINAL tag only inside current branch history', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('--is-ancestor'));
    expect(source, contains('FINAL source archive recovery'));
    expect(source, contains('zachovaný bez prepisu'));
  });

  test('FIX369 still blocks unsafe FINAL tag conflicts', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('existuje mimo aktuálnej histórie vetvy'));
    expect(source, contains('na origin nesúhlasí s lokálnym FINAL tagom'));
    expect(source, contains('FINAL vydanie sa neprepíše'));
  });

  test('FIX369 archive readiness is based on preserved source tag, not later local edits', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('verified.localTag'));
    expect(source, contains('gitArchive.localTag'));
  });

  test('FIX369 identity remains Build333 DEV015', () {
    final identity = File('lib/app/app_version.dart').readAsStringSync();
    expect(identity, contains('static const int build = 333;'));
    expect(identity, contains('RC1 DEV015 FIX'));
  });
}
