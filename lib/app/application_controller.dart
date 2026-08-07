import '../features/android_workspace/android_workspace_controller.dart';
import '../features/diagnostics/diagnostics_controller.dart';
import '../features/git_workspace/git_workspace_controller.dart';
import '../features/release_wizard/release_wizard_controller.dart';
import '../features/windows_workspace/windows_workspace_controller.dart';

/// Owns the feature controllers used by the main Release Manager workspace.
///
/// Keeping controller creation and disposal here gives the application a single
/// lifecycle boundary and prevents feature lifecycle code from spreading
/// through the main page state.
final class ApplicationController {
  ApplicationController()
      : windowsWorkspace = WindowsWorkspaceController(),
        androidWorkspace = AndroidWorkspaceController(),
        gitWorkspace = GitWorkspaceController(),
        releaseWizard = ReleaseWizardController(),
        diagnostics = DiagnosticsController();

  final WindowsWorkspaceController windowsWorkspace;
  final AndroidWorkspaceController androidWorkspace;
  final GitWorkspaceController gitWorkspace;
  final ReleaseWizardController releaseWizard;
  final DiagnosticsController diagnostics;

  bool _disposed = false;

  bool get isDisposed => _disposed;

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    windowsWorkspace.dispose();
    androidWorkspace.dispose();
    gitWorkspace.dispose();
    releaseWizard.dispose();
    diagnostics.dispose();
  }
}
