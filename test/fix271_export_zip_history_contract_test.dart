import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX271 export keeps old ZIPs and uses target workspace FIX', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf('Future<File> _createOneClickReleaseZip(');
    final export =
        source.substring(start, source.indexOf('onProgress?.call(0.10', start));
    expect(export, contains('await readWorkspaceExportFix(projectPath)'));
    expect(export, contains(r"'$workspaceFix'"));
    expect(export, isNot(contains('_lastSynchronizedZipName')));
    expect(export, isNot(contains('ReleaseManagerVersion')));
    expect(source, contains("var duplicateIndex = 2;"));
    expect(source, contains("while (await zipFile.exists())"));
    expect(source,
        isNot(contains("if (await zipFile.exists()) await zipFile.delete();")));
  });
}
