import 'dart:io';

import '../models/command_result.dart';

/// Central entry point for Flutter SDK commands.
///
/// Build 208 introduces the service without changing existing workspace
/// behaviour. Individual commands will be migrated from main.dart in small,
/// testable steps in the following builds.
class FlutterService {
  const FlutterService();

  Future<CommandResult> clean(String projectPath) =>
      run(projectPath, const <String>['clean']);

  Future<CommandResult> pubGet(String projectPath) =>
      run(projectPath, const <String>['pub', 'get']);

  Future<CommandResult> analyze(String projectPath) =>
      run(projectPath, const <String>['analyze']);

  Future<CommandResult> test(String projectPath) =>
      run(projectPath, const <String>['test']);

  Future<CommandResult> buildWindows(String projectPath) =>
      run(projectPath, const <String>['build', 'windows', '--release']);

  Future<CommandResult> buildApk(String projectPath) =>
      run(projectPath, const <String>['build', 'apk', '--release']);

  Future<CommandResult> buildAppBundle(String projectPath) =>
      run(projectPath, const <String>['build', 'appbundle', '--release']);

  Future<CommandResult> run(
    String projectPath,
    List<String> arguments,
  ) async {
    final startedAt = DateTime.now();
    final result = await Process.run(
      'flutter',
      arguments,
      workingDirectory: projectPath,
      runInShell: true,
    );
    final finishedAt = DateTime.now();

    return CommandResult(
      executable: 'flutter',
      arguments: List<String>.unmodifiable(arguments),
      exitCode: result.exitCode,
      standardOutput: result.stdout.toString(),
      standardError: result.stderr.toString(),
      startedAt: startedAt,
      finishedAt: finishedAt,
    );
  }
}
