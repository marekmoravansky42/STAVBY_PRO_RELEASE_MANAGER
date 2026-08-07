import 'package:flutter/foundation.dart';

/// Owns the mutable state shared by the Android Workspace UI and pipeline.
///
/// Build 219 extracts state first and deliberately keeps command execution,
/// dialogs, and rendering in `main.dart`. This mirrors the proven incremental
/// strategy used for the Windows Workspace in Build 218.
final class AndroidWorkspaceController extends ChangeNotifier {
  String? apkPath;
  int? apkSizeBytes;
  String? apkSha256;

  String? aabPath;
  int? aabSizeBytes;
  String? aabSha256;

  bool zipExtracted = false;
  String? extractedProjectPath;
  String? releaseExportDirectory;
  String? exportedApkPath;

  final Set<String> completedBuildSteps = <String>{};

  void resetArtifacts() {
    apkPath = null;
    apkSizeBytes = null;
    apkSha256 = null;
    aabPath = null;
    aabSizeBytes = null;
    aabSha256 = null;
    exportedApkPath = null;
    completedBuildSteps.clear();
    notifyListeners();
  }

  void resetZipSelection() {
    zipExtracted = false;
    extractedProjectPath = null;
    notifyListeners();
  }

  void markStepCompleted(String step) {
    if (completedBuildSteps.add(step)) {
      notifyListeners();
    }
  }
}
