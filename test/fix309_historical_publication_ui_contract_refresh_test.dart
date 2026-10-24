import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX309 FIX301 follows current stored-versus-live publication wording', () {
    final historical = File('test/fix301_final_publication_history_test.dart').readAsStringSync();
    expect(historical, contains('Uložený doklad publikovania:'));
    expect(historical, contains('Aktuálny online stav:'));
    expect(historical, isNot(contains('FINAL vydanie publikované:')));
  });

  test('FIX309 FIX307 no longer pins exact FIX307 identity', () {
    final historical = File('test/fix307_historical_dev008_contract_refresh_test.dart').readAsStringSync();
    expect(historical, isNot(contains("stage = 'RC1 DEV009 FIX307';")));
    expect(historical, contains(r"RC1 DEV\d{3} FIX\d+"));
  });
}
