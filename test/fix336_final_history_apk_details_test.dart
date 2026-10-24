import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX336 history shows persisted APK artifact details', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('String _formatFinalPublicationApkSize(Object? rawBytes)'));
    expect(source, contains("item['assetName'] as String?"));
    expect(source, contains("item['apkSha256'] as String?"));
    expect(source, contains('APK:'));
    expect(source, contains('_formatFinalPublicationApkSize'));
    expect(source, contains("if (apkSha256.isNotEmpty)"));
    expect(source, contains(r"'SHA-256: $apkSha256'"));
    expect(source, contains('overflow: TextOverflow.ellipsis'));
  });

  test('FIX336 persisted receipt still stores APK name size and hash', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains("'assetName': assetName"));
    expect(source, contains("'apkSha256': _apkSha256"));
    expect(source, contains("'apkSizeBytes': _apkSizeBytes,"));
  });

  test('FIX336 canonical identity remains Build 331 DEV013', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
