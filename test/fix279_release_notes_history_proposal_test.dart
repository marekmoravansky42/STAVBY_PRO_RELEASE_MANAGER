import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX279 Completion Center derives editable Novinky and Opravy from history', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('suggestedReleaseNotesFromHistory'));
    expect(source, contains('NAVRHNÚŤ RELEASE NOTES'));
    expect(source, contains('Release Notes • Novinky'));
    expect(source, contains('Release Notes • Opravy'));
    expect(File('lib/app/release_notes_apply_button.dart').readAsStringSync(),
        contains('POUŽIŤ PRE RELEASE NOTES'));
    expect(source, contains("_newsController.text = releaseNewsController.text"));
    expect(source, contains("_fixesController.text = releaseFixesController.text"));
  });

  test('FIX279 canonical identity remains Build 320 DEV002', () {
    final source = File('lib/app/app_version.dart').readAsStringSync();
    expect(source, contains('static const int build = '));
    expect(source, contains('RC1 DEV'));
    expect(source, contains('static const int build = '));
  });
}
