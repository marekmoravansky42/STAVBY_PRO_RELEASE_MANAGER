import 'dart:io';

enum WorkspaceTerminalKind { commandPrompt, powerShell }

typedef WorkspaceTerminalProcessStarter = Future<void> Function(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
});

/// Opens a native Windows terminal in [workspace] without executing a command.
///
/// `cmd /c start` gives the child terminal its own visible window while the
/// selected workspace remains its current directory.
final class WorkspaceTerminalLauncher {
  const WorkspaceTerminalLauncher._();

  static Future<void> open(
    WorkspaceTerminalKind terminal,
    String workspace, {
    WorkspaceTerminalProcessStarter? startProcess,
  }) async {
    final normalizedWorkspace = workspace.trim();
    if (normalizedWorkspace.isEmpty) {
      throw ArgumentError.value(workspace, 'workspace', 'Workspace chýba.');
    }
    if (!Platform.isWindows) {
      throw UnsupportedError('CMD a PowerShell sú dostupné iba vo Windows.');
    }
    if (!await Directory(normalizedWorkspace).exists()) {
      throw StateError('Workspace neexistuje: $normalizedWorkspace');
    }

    final launcher = startProcess ?? _startProcess;
    await launcher(
      'cmd.exe',
      _launchArguments(terminal),
      workingDirectory: normalizedWorkspace,
    );
  }

  static List<String> _launchArguments(WorkspaceTerminalKind terminal) {
    final terminalArguments = switch (terminal) {
      WorkspaceTerminalKind.commandPrompt => <String>['cmd.exe', '/k'],
      WorkspaceTerminalKind.powerShell => <String>[
          'powershell.exe',
          '-NoLogo',
          '-NoProfile',
          '-NoExit',
        ],
    };
    return <String>['/d', '/c', 'start', '', ...terminalArguments];
  }

  static Future<void> _startProcess(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) async {
    await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: false,
    );
  }
}
