import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('lib/main.dart').readAsStringSync();

  test('FIX350 Release Dashboard can reopen FINAL Publish Center', () {
    expect(source, contains('Future<void> _openFinalPublishCenterFromDashboard()'));
    expect(source, contains('releaseDashboardOpenFinalPublishCenterButton'));
    expect(source, contains('releaseDashboardFinalCardPublishButton'));
    expect(source, contains("'PUBLIKOVAŤ FINAL'"));
    expect(source, contains('_showFinalPublishCenter(releaseZip: File(zipPath))'));
  });

  test('FIX350 re-entry requires persisted FINAL ZIP, integrity and Publish Gate', () {
    expect(source, contains('_dashboardLastVerifiedExportZipPath'));
    expect(source, contains("_dashboardReleaseIntegrityStatus == 'INTEGRITY OK'"));
    expect(source, contains("_dashboardPublishGateStatus == 'POVOLENÉ'"));
    expect(source, contains("releaseDirectory.toUpperCase().contains('_FINAL')"));
  });

  test('FIX350 canonical identity starts Build 333 DEV015', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, contains('static const int build = 333;'));
    expect(version, contains("static const String stage = 'RC1 DEV015 FIX"));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+333\b')));
  });
}
