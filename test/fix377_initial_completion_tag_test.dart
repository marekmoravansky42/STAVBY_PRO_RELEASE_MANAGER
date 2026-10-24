import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/app/build_completion_tag.dart';

void main() {
  for (final workspaceStage in ['dev', 'rc1']) {
    for (final entry in {
      'FINAL': 'v8.0.0-final-b333',
      'DEV': 'v8.0.0-build333',
      'RC': 'v8.0.0-rc1',
    }.entries) {
      test('initial ${entry.key} tag overrides workspace $workspaceStage stage',
          () {
        final savedPreferences = <String, Object>{
          'releaseType': entry.key,
          'commit': false,
          'push': false,
          'tag': true,
          'exportZip': false,
          'buildReport': false,
          'history': false,
          'synchronizeZip': false,
        };
        final identity = (version: '8.0.0', build: 333, stage: workspaceStage);
        final releaseType = savedPreferences['releaseType'] as String;
        final controller = TextEditingController(
          text: suggestBuildCompletionTag(
              identity: identity, releaseType: releaseType),
        );
        addTearDown(controller.dispose);
        expect(controller.text, entry.value);
      });
    }
  }

  test(
      'dialog initializes from selected type without applying recommended options',
      () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf('Future<void> _showBuildCompletionCenter()');
    final initialization = source.substring(
      start,
      source.indexOf('final completionData = await showDialog', start),
    );
    expect(
        initialization,
        contains(
            "(savedPreferences['releaseType'] as String?) ?? inferReleaseType()"));
    expect(
        initialization,
        contains('suggestBuildCompletionTag('));
    expect(initialization, contains('releaseType: releaseType'));
    expect(initialization,
        contains('TextEditingController(text: suggestedTag())'));
    expect(initialization, isNot(contains('_gitTagForBuild(identity)')));
    expect(initialization, isNot(contains('applyRecommendedOptions();')));
  });
}
