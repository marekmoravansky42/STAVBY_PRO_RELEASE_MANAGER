import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX322 keeps release-history dialog actions inside AlertDialog', () {
    final source = File('lib/main.dart').readAsStringSync();
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    final start = source.indexOf('Future<void> _showReleaseHistoryDialog() async');
    final end = source.indexOf('Future<Directory> _resolveDevelopmentZipRoot', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final dialog = source.substring(start, end);

    expect(dialog, contains('AlertDialog('));
    expect(dialog, contains('actions: <Widget>['));
    // Historical FIX322 regression must remain valid for later FIXes in Build 330 / DEV012.
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });

  test('FIX322 closes ConstrainedBox and SizedBox before FINAL history actions', () {
    final source = File('lib/main.dart').readAsStringSync();

    final start = source.indexOf('Future<void> _showFinalPublicationHistory() async');
    final end = source.indexOf('Future<void> _persistVerifiedFinalPublication', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final dialog = source.substring(start, end);

    expect(dialog, contains('ConstrainedBox('));
    expect(dialog, contains('actions: <Widget>['));
    expect(dialog, contains("Text('ZAVRIEŤ')"));
  });
}
