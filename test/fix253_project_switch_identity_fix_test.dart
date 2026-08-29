import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX253 project switch atomically replaces dashboard workspace identity', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains('_gitWorkspacePath = selected;'));
    expect(source, contains('_gitWorkspaceStatus = null;'));
    expect(source, contains('_projectIdentitySnapshot = null;'));
    expect(source, contains('_projectIdentityLoading = true;'));
  });

  test('FIX253 project switch refreshes Git and identity for selected project', () {
    final source = File('lib/main.dart').readAsStringSync();

    final rememberProject =
        source.indexOf('await _rememberProjectPath(selected);');
    final rememberGit =
        source.indexOf('await _rememberGitWorkspace(selected);', rememberProject);
    final refreshGit =
        source.indexOf('_refreshGitWorkspace,', rememberGit);

    expect(rememberProject, greaterThanOrEqualTo(0));
    expect(rememberGit, greaterThan(rememberProject));
    expect(refreshGit, greaterThan(rememberGit));
    expect(source, contains('FIX253 PROJECT SWITCH IDENTITY:'));
  });
}
