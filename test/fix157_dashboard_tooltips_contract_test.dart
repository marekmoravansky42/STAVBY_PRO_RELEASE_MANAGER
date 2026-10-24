import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard build and release actions expose contextual tooltips', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains('Rýchle testovanie buildu.'));
    expect(source, contains("Nie je to kompletný One Click Release"));
    expect(source, contains('Dôkladný čistý build:'));
    expect(source, contains('Kompletný \$_oneClickReleaseMode release workflow:'));
    expect(source, contains('Skontroluje zdrojový kód projektu'));
    expect(source, contains('Spustí automatické Flutter testy'));
    expect(source, contains('Vytvorí iba Windows Release build'));
    expect(source, contains('Vytvorí Release ZIP'));
    expect(source, contains("waitDuration: const Duration(milliseconds: 450)"));
  });
}
