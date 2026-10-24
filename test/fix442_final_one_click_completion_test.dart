import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('lib/main.dart').readAsStringSync();

  test('FIX442 blocks FINAL before build when Release Notes are empty', () {
    expect(source, contains("selected == 'FINAL' &&"));
    expect(source,
        contains('FINAL release vyžaduje vyplnené Novinky alebo Opravy.'));
    expect(source, contains('Najprv ich doplň v Build Completion Center.'));
  });

  test('FIX442 completes and verifies FINAL Git archive before Publish Center',
      () {
    expect(
      source,
      contains(
        RegExp(
          r'_archiveFinalSourceFromPublishCenter\('
          r'\s*requireConfirmation:\s*false\s*,',
        ),
      ),
    );
    expect(
        source, contains('final archive = await _verifyFinalSourceArchive();'));
    expect(source, contains('FINAL Git archív overený'));
    expect(
        source,
        contains(
            'await _showFinalPublishCenter(releaseZip: finalReleaseZip!);'));
  });

  test('manual Publish Center archive action retains its confirmation', () {
    expect(
      source,
      contains(
        RegExp(
          r'Future<bool>\s+_archiveFinalSourceFromPublishCenter\('
          r'\s*\{\s*bool\s+requireConfirmation\s*=\s*true\s*\}'
          r'\s*\)\s*async',
        ),
      ),
    );
    expect(
        source, contains("title: const Text('Uložiť FINAL zdroj do Gitu?')"));
  });
}
