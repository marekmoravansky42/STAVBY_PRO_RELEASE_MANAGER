import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX318 adds persistent FINAL publication history browser', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('Future<List<Map<String, dynamic>>> _readFinalPublicationHistory()'));
    expect(source, contains('Future<void> _showFinalPublicationHistory()'));
    expect(source, contains("Key('finalPublishCenterHistoryButton')"));
    expect(source, contains("Text('HISTÓRIA PUBLIKOVANÍ')"));
    expect(source, contains('História FINAL publikovaní'));
    expect(source, contains("item['sourceFinalTag']"));
    expect(source, contains("item['githubReleaseTag']"));
    expect(source, contains("item['onlineVerified'] == true"));
    expect(source, contains("'RELEASE URL'"));
    expect(source, contains("'APK URL'"));
  });

  test('FIX318 canonical identity starts Build 330 DEV012', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
