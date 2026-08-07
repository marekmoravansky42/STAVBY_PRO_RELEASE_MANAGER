import 'dart:io';

import 'project_platform.dart';
import 'project_workspace.dart';

class PreflightCheck {
  const PreflightCheck(this.name, this.passed, this.message);
  final String name;
  final bool passed;
  final String message;
}

class PreflightReport {
  const PreflightReport(this.checks);
  final List<PreflightCheck> checks;
  bool get passed => checks.every((check) => check.passed);
}

class PreflightValidator {
  const PreflightValidator();

  Future<PreflightReport> validate(ProjectWorkspace workspace) async {
    final checks = <PreflightCheck>[
      PreflightCheck('Flutter projekt', true, workspace.rootPath),
      PreflightCheck(
        'Platformy',
        workspace.platforms.isNotEmpty,
        workspace.platforms.isEmpty
            ? 'Projekt nemá rozpoznaný platformový adresár.'
            : workspace.platforms.map((p) => p.label).join(', '),
      ),
    ];
    try {
      final result = await Process.run(
        'flutter',
        const <String>['--version'],
        runInShell: true,
      );
      checks.add(PreflightCheck(
        'Flutter SDK',
        result.exitCode == 0,
        result.exitCode == 0
            ? result.stdout.toString().split('\n').first.trim()
            : 'Flutter SDK nie je dostupné.',
      ));
    } catch (_) {
      checks.add(const PreflightCheck(
        'Flutter SDK',
        false,
        'Flutter SDK nie je dostupné.',
      ));
    }
    return PreflightReport(List<PreflightCheck>.unmodifiable(checks));
  }
}
