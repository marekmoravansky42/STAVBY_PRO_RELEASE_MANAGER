import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX321 keeps FINAL publication history constrained and scroll-safe', () {
    final source = File('lib/main.dart').readAsStringSync();
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    final start = source.indexOf('Future<void> _showFinalPublicationHistory() async');
    final end = source.indexOf('Future<void> _persistVerifiedFinalPublication', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final historyDialog = source.substring(start, end);

    expect(historyDialog, contains('width: 760'));
    expect(historyDialog, contains('ConstrainedBox('));
    expect(historyDialog, contains('maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.70'));
    expect(historyDialog, contains('ListView.separated('));
    expect(historyDialog, contains('História FINAL publikovaní'));
    expect(historyDialog, contains("child: const Text('ZAVRIEŤ')"));

    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
