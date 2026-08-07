import 'package:flutter/foundation.dart';

import '../../services/git_service.dart';

/// Owns the mutable state used by the Git workspace.
///
/// Command execution remains in the existing UI flow during extraction phase 1;
/// later phases can move those operations behind this controller safely.
class GitWorkspaceController extends ChangeNotifier {
  String? workspacePath;
  GitWorkspaceStatus? workspaceStatus;
  bool workspaceLoading = false;
  bool repositoryInitializing = false;
  bool commitRunning = false;
  bool tagRunning = false;
  bool restoreRunning = false;
  bool diffRunning = false;
  List<GitCommitEntry> history = const <GitCommitEntry>[];

  bool get hasWorkspace => workspacePath != null && workspacePath!.trim().isNotEmpty;
  bool get isRepository => workspaceStatus?.isRepository == true;
  bool get isBusy =>
      workspaceLoading ||
      repositoryInitializing ||
      commitRunning ||
      tagRunning ||
      restoreRunning ||
      diffRunning;

  void reset({bool keepWorkspacePath = false}) {
    if (!keepWorkspacePath) workspacePath = null;
    workspaceStatus = null;
    workspaceLoading = false;
    repositoryInitializing = false;
    commitRunning = false;
    tagRunning = false;
    restoreRunning = false;
    diffRunning = false;
    history = const <GitCommitEntry>[];
    notifyListeners();
  }

  void refreshUi() => notifyListeners();
}
