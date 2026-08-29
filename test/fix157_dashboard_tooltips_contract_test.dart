import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard build and release actions expose contextual tooltips', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains("tooltip: 'Rýchle testovanie buildu."));
    expect(source, contains("Nie je to kompletný One Click Release"));
    expect(source, contains("tooltip: 'Dôkladný čistý build:"));
    expect(source, contains("message: 'Kompletný \$_oneClickReleaseMode release workflow:"));
    expect(source, contains("tooltip: 'Skontroluje zdrojový kód projektu"));
    expect(source, contains("tooltip: 'Spustí automatické Flutter testy"));
    expect(source, contains("tooltip: 'Vytvorí iba Windows Release build"));
    expect(source, contains("tooltip: 'Vytvorí Release ZIP"));
    expect(source, contains("waitDuration: const Duration(milliseconds: 450)"));
  });
}
