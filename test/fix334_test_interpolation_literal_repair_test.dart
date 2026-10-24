import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX334 FIX333 source snippets are raw literals', () {
    final source = File(
      'test/fix333_final_history_readable_timestamp_test.dart',
    ).readAsStringSync();

    expect(
        source,
        contains(
            r'''contains(r"return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';")'''));
    expect(source, contains("contains('Publikované:')"));
    expect(source, contains("contains('_formatFinalPublicationTimestamp')"));
  });

  test('FIX334 production timestamp formatter remains present', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(
        source,
        contains(
            'String _formatFinalPublicationTimestamp(Object? rawTimestamp)'));
    expect(source, contains('final local = parsed.toLocal();'));
  });

  test('FIX334 canonical identity remains Build 331 DEV013', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version,
        matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
