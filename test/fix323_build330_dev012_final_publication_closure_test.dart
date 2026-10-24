import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX323 closes Build 330 DEV012 FINAL publication workflow contracts', () {
    final source = File('lib/main.dart').readAsStringSync();
    final githubService = File('lib/services/github_settings_service.dart').readAsStringSync();
    final version = File('lib/app/app_version.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    // Persisted publication receipts + history browser.
    expect(source, contains('final_publications.json'));
    expect(source, contains('_persistVerifiedFinalPublication('));
    expect(source, contains('_readPersistedFinalPublication()'));
    expect(source, contains('Future<void> _showFinalPublicationHistory() async'));
    expect(source, contains('História FINAL publikovaní'));
    expect(source, contains('ListView.separated('));
    expect(source, contains('maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.70'));

    // Online verification + revalidation.
    expect(githubService, contains('class GitHubPublicationVerificationResult'));
    expect(githubService, contains('verifyPublishedRelease({'));
    expect(source, contains('_revalidateFinalPublicationOnline()'));
    expect(source, contains("Key('finalPublishCenterRevalidateButton')"));
    expect(source, contains("updated['lastRevalidatedAt']"));

    // Publish Gate / GitHub Release / APK publication actions remain wired.
    expect(source, contains('Publish Gate'));
    expect(source, contains('GitHub Release'));
    expect(source, contains('APK'));
    expect(source, contains('verifyPublishedRelease('));
    expect(source, contains('PUBLIKOVANIE BOLO ÚSPEŠNE DOKONČENÉ A ONLINE OVERENÉ'));

    // Stored receipt actions remain available in FINAL Publish Center.
    expect(source, contains("finalPublishCenterOpenStoredReleaseButton"));
    expect(source, contains("finalPublishCenterCopyStoredReleaseUrlButton"));
    expect(source, contains("finalPublishCenterCopyStoredApkUrlButton"));
    expect(source, contains("OTVORIŤ GITHUB RELEASE"));
    expect(source, contains("KOPÍROVAŤ RELEASE URL"));
    expect(source, contains("KOPÍROVAŤ APK URL"));

    // Build 330 / DEV012 closure identity.
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    // Historical FIX323 closure stays valid for later FIXes in Build 330 / DEV012.
    expect(version, matches(RegExp(r'static const int build = \d+;')));
    expect(version, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
    expect(pubspec, matches(RegExp(r'version: 8\.0\.0(?:-dev\.\d+)?\+\d+\b')));
  });
}
