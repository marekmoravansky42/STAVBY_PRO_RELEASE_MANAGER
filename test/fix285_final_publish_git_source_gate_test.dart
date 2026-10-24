import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX285 Git source gate remains enforced by verified archive readiness', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('final gitArchive = await _verifyFinalSourceArchive();'));
    expect(source, contains('gitArchive.workspaceClean'));
    expect(source, contains('gitArchive.localTag'));
    expect(source, contains('gitArchive.remoteTag'));
    expect(source, contains('gitArchive.branchPushed'));
    expect(source, contains('notesReady'));
    expect(source, contains('gitReady'));
    expect(source, contains('Git zdrojový archív:'));
  });

  test('FIX285 canonical identity contract does not pin a future FIX', () {
    final source = File('lib/app/app_version.dart').readAsStringSync();
    expect(source, matches(RegExp(r'static const int build = \d+;')));
    expect(source, matches(RegExp(r"static const String stage = 'RC1 DEV\d{3} FIX\d+';")));
  });
}
