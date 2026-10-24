import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/app/workspace_terminal_launcher.dart';

void main() {
  test(
      'FIX432 opens CMD and PowerShell in the selected workspace without a command',
      () async {
    final invocations = <({
      String executable,
      List<String> arguments,
      String workingDirectory,
    })>[];
    Future<void> capture(
      String executable,
      List<String> arguments, {
      required String workingDirectory,
    }) async {
      invocations.add((
        executable: executable,
        arguments: arguments,
        workingDirectory: workingDirectory,
      ));
    }

    final workspace = Directory.current.path;
    await WorkspaceTerminalLauncher.open(
      WorkspaceTerminalKind.commandPrompt,
      workspace,
      startProcess: capture,
    );
    await WorkspaceTerminalLauncher.open(
      WorkspaceTerminalKind.powerShell,
      workspace,
      startProcess: capture,
    );

    expect(invocations, hasLength(2));
    expect(invocations[0].executable, 'cmd.exe');
    expect(invocations[0].workingDirectory, workspace);
    expect(invocations[0].arguments,
        <String>['/d', '/c', 'start', '', 'cmd.exe', '/k']);
    expect(invocations[1].executable, 'cmd.exe');
    expect(invocations[1].workingDirectory, workspace);
    expect(invocations[1].arguments, <String>[
      '/d',
      '/c',
      'start',
      '',
      'powershell.exe',
      '-NoLogo',
      '-NoProfile',
      '-NoExit',
    ]);
  });

  test('FIX432 refuses a missing workspace before starting a terminal',
      () async {
    var wasStarted = false;
    Future<void> capture(
      String _,
      List<String> __, {
      required String workingDirectory,
    }) async {
      wasStarted = true;
    }

    await expectLater(
      WorkspaceTerminalLauncher.open(
        WorkspaceTerminalKind.commandPrompt,
        '${Directory.current.path}\\missing-workspace-for-fix432',
        startProcess: capture,
      ),
      throwsStateError,
    );
    expect(wasStarted, isFalse);
  });
}
