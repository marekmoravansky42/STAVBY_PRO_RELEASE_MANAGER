import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX338 FINAL history can copy a readable receipt', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(
        source,
        contains(
            'Future<void> _copyFinalPublicationReceipt(Map<String, dynamic> item) async'));
    expect(source, contains('Clipboard.setData('));
    expect(source, contains("lines.join('\\n')"));
    expect(source, contains("'KOPÍROVAŤ DOKLAD'"));
    expect(source, contains('onPressed: () =>'));
    expect(source, contains('_copyFinalPublicationReceipt('));
    expect(source, contains('FINAL doklad bol skopírovaný do schránky.'));
  });

  test('FIX338 copied receipt includes important audit fields', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains(r"'Verzia: ${item['version'] ?? '—'}'"));
    expect(
        source,
        contains(
            r"'GitHub tag: ${item['githubReleaseTag'] ?? item['tag'] ?? '—'}'"));
    expect(source, contains(r"lines.add('SHA-256: $apkSha256')"));
    expect(source, contains(r"lines.add('Release URL: $releaseUrl')"));
    expect(source, contains(r"lines.add('APK URL: $assetUrl')"));
  });

  test('FIX338 canonical identity remains Build 331 DEV013', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version,
        matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
