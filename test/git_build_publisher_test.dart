import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/services/git_service.dart';

void main() {
  test('Git Build Publisher vytvorí commit, tag a odošle ich do origin', () async {
    final root = await Directory.systemTemp.createTemp('rm_git_publisher_');
    final workspace = Directory('${root.path}${Platform.pathSeparator}workspace');
    final remote = Directory('${root.path}${Platform.pathSeparator}remote.git');
    await workspace.create();
    await remote.create();

    Future<ProcessResult> git(List<String> args, {String? cwd}) => Process.run(
          'git',
          args,
          workingDirectory: cwd,
          runInShell: true,
        );

    try {
      expect((await git(<String>['init', '--bare'], cwd: remote.path)).exitCode, 0);
      expect((await git(<String>['init', '-b', 'develop'], cwd: workspace.path)).exitCode, 0);
      await git(<String>['config', 'user.name', 'Release Manager Test'], cwd: workspace.path);
      await git(<String>['config', 'user.email', 'release-manager@example.invalid'], cwd: workspace.path);
      await git(<String>['remote', 'add', 'origin', remote.path], cwd: workspace.path);

      final initial = File('${workspace.path}${Platform.pathSeparator}pubspec.yaml');
      await initial.writeAsString('name: demo\nversion: 1.0.0+1\n');
      await git(<String>['add', '--all'], cwd: workspace.path);
      await git(<String>['commit', '-m', 'Initial'], cwd: workspace.path);
      await git(<String>['push', '-u', 'origin', 'develop'], cwd: workspace.path);

      await initial.writeAsString('name: demo\nversion: 1.0.1+2\n');
      final result = await const GitService().publishBuild(
        workspace.path,
        commitMessage: 'Build 2 - test publishera',
        tagName: 'v1.0.1-dev-b2',
      );

      expect(result.success, isTrue, reason: result.message);
      expect(result.commitSha, isNotEmpty);
      expect((await git(<String>['show-ref', '--verify', 'refs/tags/v1.0.1-dev-b2'], cwd: remote.path)).exitCode, 0);
      expect((await git(<String>['show-ref', '--verify', 'refs/heads/develop'], cwd: remote.path)).exitCode, 0);
    } finally {
      await root.delete(recursive: true);
    }
  });
}
