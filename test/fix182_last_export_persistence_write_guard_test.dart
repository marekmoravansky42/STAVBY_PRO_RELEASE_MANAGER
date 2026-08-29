import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File('lib/main.dart').readAsStringSync();
  });

  test('last export metadata save is guarded against filesystem failures', () {
    final start = source.indexOf('Future<void> _saveLastVerifiedExportZipPath(');
    final end = source.indexOf('Future<void> _loadLastVerifiedExportZipPath(', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final block = source.substring(start, end);

    expect(block, contains('try {'));
    expect(block, contains('catch (error)'));
    expect(
      block,
      contains('Posledný export ZIP sa nepodarilo uložiť: \$error'),
    );
  });

  test('verified export persistence remains best effort at all call sites', () {
    expect(
      source.split('unawaited(_saveLastVerifiedExportZipPath(').length - 1,
      greaterThanOrEqualTo(5),
    );
  });
}
