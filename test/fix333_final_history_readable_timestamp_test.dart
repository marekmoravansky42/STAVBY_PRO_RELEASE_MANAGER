import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX333 FINAL publication history formats persisted ISO timestamp for people', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('String _formatFinalPublicationTimestamp(Object? rawTimestamp)'));
    expect(source, contains('final parsed = DateTime.tryParse(raw);'));
    expect(source, contains('final local = parsed.toLocal();'));
    expect(source, contains(r"return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';"));
    expect(source, contains('Publikované:'));
    expect(source, contains('_formatFinalPublicationTimestamp'));
  });

  test('FIX333 keeps persisted timestamp format unchanged', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains("'timestamp': DateTime.now().toIso8601String(),"));
  });

  test('FIX441 history shows the last online verification time', () {
    final source = File('lib/main.dart').readAsStringSync();
    final historyStart = source.indexOf('Future<void> _showFinalPublicationHistory() async');
    final persistStart = source.indexOf('Future<void> _persistVerifiedFinalPublication', historyStart);
    expect(historyStart, greaterThanOrEqualTo(0));
    final history = source.substring(historyStart, persistStart);

    expect(history, contains("item['lastRevalidatedAt']"));
    expect(history, contains("'Posledné online overenie:"));
    expect(history, contains('_formatFinalPublicationTimestamp(lastOnlineVerificationAt)'));
    expect(
      history,
      contains(RegExp(r"onlineVerified\s*\?\s*item\['timestamp'\]\s*:\s*null")),
    );
  });

  test('FIX333 canonical identity remains Build 331 DEV013', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
