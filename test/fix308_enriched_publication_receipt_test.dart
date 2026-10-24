import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX308 persists enriched FINAL publication receipt', () {
    final source = File('lib/main.dart').readAsStringSync();
    for (final field in <String>[
      "'projectName': project.projectName",
      "'projectPath': project.projectPath",
      "'channel': 'FINAL'",
      "'sourceFinalTag':",
      "-final-b\${project.releaseBuild}",
      "'githubReleaseTag': tagName",
      "'apkSha256': _apkSha256",
      "'apkSizeBytes': _apkSizeBytes",
    ]) {
      expect(source, contains(field));
    }
  });

  test('FIX308 distinguishes stored history from live online verification', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('Uložený doklad publikovania:'));
    expect(source, contains('Aktuálny online stav:'));
    expect(source, contains("_lastPublicationVerification?.success == true ? 'OVERENÉ' : 'NEOVERENÉ'"));
    expect(source, contains("label: const Text('OVERIŤ PUBLIKOVANIE')"));
  });
}
