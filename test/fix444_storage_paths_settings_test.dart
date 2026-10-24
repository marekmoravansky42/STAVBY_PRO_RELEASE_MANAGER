import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('lib/main.dart').readAsStringSync();

  test('FIX444 collects all persisted export destinations in Settings and Help', () {
    final start = source.indexOf('Widget _buildStoragePathsCard()');
    final end = source.indexOf('Widget _buildSettingsHelpCenterPage()', start);
    final card = source.substring(start, end);
    expect(card, contains('Cesty uloženia'));
    expect(card, contains('STAVBY PRO – DEV Windows a release ZIP'));
    expect(card, contains('STAVBY PRO – Android APK'));
    expect(card, contains('Release Manager – aktualizačný ZIP'));
    expect(card, contains('_chooseWindowsReleaseExportDirectory'));
    expect(card, contains('_chooseAndroidReleaseExportDirectory'));
    expect(card, contains('_chooseManagerUpdateDirectory'));
    expect(card, contains('constraints.maxWidth < 760'));
    expect(card, contains('SizedBox(width: cardWidth, child: item)'));
  });

  test('FIX444 renders the single card in the Settings and Help center', () {
    final start = source.indexOf('Widget _buildSettingsHelpCenterPage()');
    final end = source.indexOf('void _resetDashboardReleaseIntegrityStatus()', start);
    final page = source.substring(start, end);
    expect(page, contains('_buildStoragePathsCard()'));
    expect(page, contains('return Wrap('));
    expect(page, contains('SizedBox(width: cardWidth, child: group)'));
    expect(page, isNot(contains('childAspectRatio: 2.55')));
  });
}