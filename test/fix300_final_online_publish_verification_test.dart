import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX300 verifies version.json, GitHub Release and APK after publish', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final service = File('lib/services/github_settings_service.dart').readAsStringSync();
    expect(service, contains('class GitHubPublicationVerificationResult'));
    expect(service, contains('verifyPublishedRelease({'));
    expect(service, contains("/contents/version.json"));
    expect(service, contains("/releases/tags/\$encodedTag"));
    expect(service, contains("asset['name']?.toString() != assetName"));
    expect(mainSource, contains('_lastPublicationVerification'));
    expect(mainSource, contains('final verification = await _githubSettingsService.verifyPublishedRelease('));
    expect(mainSource, contains('Online version.json:'));
    expect(mainSource, contains('Online GitHub Release:'));
    expect(mainSource, contains('Online APK asset:'));
    expect(mainSource, contains('PUBLIKOVANIE BOLO ÚSPEŠNE DOKONČENÉ A ONLINE OVERENÉ'));
  });

  test('FIX300 canonical identity remains valid after later builds', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
