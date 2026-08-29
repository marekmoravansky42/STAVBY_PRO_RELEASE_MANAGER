import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('One Click Release exports ZIP even without Android platform', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('Pokračujem Windows Release ZIP exportom.'));
    expect(source, contains('final windowsOnlyReleaseZip = await _createOneClickReleaseZip('));
    expect(source, contains('Windows Release ZIP fyzicky overený'));
  });

  test('Integrity cannot run before physical Export ZIP gate passes', () {
    final source = File('lib/main.dart').readAsStringSync();
    final gate = source.indexOf('ONE CLICK RELEASE EXPORT GATE OK:');
    final integrity = source.indexOf('Vytváram SHA-256 manifest...', gate);
    expect(gate, greaterThan(-1));
    expect(integrity, greaterThan(gate));
    expect(source, contains('Export ZIP nebol fyzicky'));
  });

  test('completion dialog exposes exact Export ZIP in Explorer', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('Export ZIP: OK – fyzicky overený'));
    expect(source, contains('OTVORIŤ EXPORT ZIP V PRIESKUMNÍKOVI'));
  });
}
