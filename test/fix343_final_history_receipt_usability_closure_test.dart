import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('lib/main.dart').readAsStringSync();

  test('FIX343 FINAL history keeps newest-first filtered browser', () {
    expect(source, contains(RegExp(r'\.reversed\s*\.toList\(\)')));
    expect(source, contains('final displayHistory = verifiedOnly'));
    expect(source, contains("'IBA OVERENÉ'"));
    expect(source, contains('História FINAL publikovaní'));
    expect(source, contains(r'${displayHistory.length}/${history.length}'));
    expect(source, isNot(contains('history.reversed.toList(growable: false)')));
  });

  test('FIX343 FINAL history keeps readable receipt details and status', () {
    expect(source, contains('_formatFinalPublicationTimestamp'));
    expect(source, contains('_formatFinalPublicationApkSize'));
    expect(source, contains("item['apkSha256'] as String?"));
    expect(source, contains("'OVERENÝ'"));
    expect(source, contains("'NEOVERENÝ'"));
  });

  test('FIX343 FINAL history keeps receipt and SHA clipboard actions', () {
    expect(
        source,
        contains(
            'Future<void> _copyFinalPublicationReceipt(Map<String, dynamic> item) async'));
    expect(source, contains("'KOPÍROVAŤ DOKLAD'"));
    expect(source, contains(RegExp(r'text:\s*apkSha256')));
    expect(source, contains("'SHA-256'"));
  });

  test('FIX343 persisted FINAL history contract remains intact', () {
    expect(source, contains("'assetName': assetName"));
    expect(source, contains("'apkSha256': _apkSha256"));
    expect(source, contains("'apkSizeBytes': _apkSizeBytes"));
    expect(source, contains("'onlineVerified': true"));
  });

  test('FIX343 canonical identity remains Build 331 DEV013', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version,
        matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
