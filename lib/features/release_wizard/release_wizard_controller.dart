import 'package:flutter/foundation.dart';

/// Owns the mutable state used by Release Wizard 3.0.
///
/// Pipeline execution remains in the existing page during extraction phase 1.
/// Keeping its state here makes the next service/page extraction safe and
/// prevents additional wizard fields from accumulating in `main.dart`.
class ReleaseWizardController extends ChangeNotifier {
  static const List<String> pipelineSteps = <String>[
    'Flutter clean',
    'Flutter pub get',
    'Flutter analyze',
    'Flutter test',
    'Windows Release build',
    'Release APK build',
    'Release AAB build',
    'Vytvorenie release balíka',
  ];

  bool running = false;
  int step = 0;
  String status = 'Pripravený na spustenie.';
  String? reportPath;
  String? releaseDirectory;
  final List<String> completedSteps = <String>[];

  double get progress {
    if (running) {
      return (step / pipelineSteps.length).clamp(0.0, 1.0);
    }
    return completedSteps.isEmpty ? 0.0 : 1.0;
  }

  bool get hasOutput => reportPath != null || releaseDirectory != null;

  void prepareRun() {
    running = true;
    step = 0;
    status = 'Spúšťam Release Wizard 3.0...';
    reportPath = null;
    releaseDirectory = null;
    completedSteps.clear();
    notifyListeners();
  }

  void beginStep(String title) {
    step += 1;
    status = title;
    notifyListeners();
  }

  void completeStep(String title) {
    if (!completedSteps.contains(title)) completedSteps.add(title);
    notifyListeners();
  }

  void finish({required bool success}) {
    running = false;
    status = success
        ? 'Release Wizard 3.0 bol úspešne dokončený.'
        : 'Release Wizard 3.0 nebol dokončený.';
    notifyListeners();
  }

  void reset() {
    running = false;
    step = 0;
    status = 'Pripravený na spustenie.';
    reportPath = null;
    releaseDirectory = null;
    completedSteps.clear();
    notifyListeners();
  }

  void refreshUi() => notifyListeners();
}
