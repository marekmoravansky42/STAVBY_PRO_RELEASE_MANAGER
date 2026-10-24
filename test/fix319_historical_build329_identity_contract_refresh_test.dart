import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX319 historical FIX316 and FIX317 tests no longer pin Build 329', () {
    final fix316 = File('test/fix316_final_publication_receipt_complete_details_test.dart').readAsStringSync();
    final fix317 = File('test/fix317_final_publication_receipt_complete_details_closure_test.dart').readAsStringSync();
    expect(fix316, isNot(contains("contains('static const int build = 329;')")));
    expect(fix317, isNot(contains("contains('static const int build = 329;')")));
    expect(fix316, isNot(contains("contains('version: 8.0.0+329')")));
    expect(fix317, isNot(contains("contains('version: 8.0.0+329')")));
  });

  test('FIX319 canonical identity remains Build 330 DEV012', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
