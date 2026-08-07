import 'package:flutter/foundation.dart';

/// Owns the mutable state shared by the Windows Workspace UI and pipeline.
///
/// Build 218 intentionally extracts state first while preserving the existing
/// command and dialog flow in `main.dart`. Later refactoring phases can move
/// the UI and process execution behind this controller without changing the
/// public state contract again.
final class WindowsWorkspaceController extends ChangeNotifier {
  final Set<String> completedBuildSteps = <String>{};

  final Map<String, bool?> environmentChecks = <String, bool?>{
    'Flutter SDK': null,
    'Dart SDK': null,
    'Git': null,
    'pubspec.yaml': null,
    'analysis_options.yaml': null,
    'Priečinok lib': null,
    'Windows Desktop': null,
    'Priečinok windows': null,
    'Verzia projektu': null,
  };

  final Map<String, String> environmentDetails = <String, String>{};

  DateTime? environmentCheckedAt;

  void resetBuildProgress() {
    completedBuildSteps.clear();
    notifyListeners();
  }

  void resetEnvironment() {
    for (final key in environmentChecks.keys) {
      environmentChecks[key] = null;
    }
    environmentDetails.clear();
    environmentCheckedAt = null;
    notifyListeners();
  }

  void markStepCompleted(String step) {
    if (completedBuildSteps.add(step)) {
      notifyListeners();
    }
  }

  void markStepIncomplete(String step) {
    if (completedBuildSteps.remove(step)) {
      notifyListeners();
    }
  }
}
