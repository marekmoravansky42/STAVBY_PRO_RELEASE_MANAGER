import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stavby_pro_release_manager/services/workspace_export_identity.dart';

void main() {
  late Directory root;
  late File identity;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('fix375_export_');
    identity = File(path.join(root.path, 'lib', 'app', 'app_version.dart'));
    await identity.parent.create(recursive: true);
  });

  tearDown(() async => root.delete(recursive: true));

  test('FIX372 sync and older manager cannot override target FIX375', () async {
    final sync =
        File(path.join(root.path, '.release_manager', 'last_sync.json'));
    await sync.parent.create(recursive: true);
    await sync.writeAsString('{"zipName":"MANAGER_FIX372_SYNC.zip"}');
    final olderManager = Directory(path.join(root.path, 'older_manager'));
    final olderIdentity =
        File(path.join(olderManager.path, 'lib', 'app', 'app_version.dart'));
    await olderIdentity.parent.create(recursive: true);
    await olderIdentity
        .writeAsString("static const String stage = 'RC1 DEV015 FIX373';\n");
    expect(await readWorkspaceExportFix(olderManager.path), '_FIX373');
    await identity
        .writeAsString("static const String stage = 'RC1 DEV015 FIX375';\n");
    final fix = await readWorkspaceExportFix(root.path);
    expect(fix, '_FIX375');
    expect(
        'STAVBY_PRO_RELEASE_MANAGER_8.0.0_DEV_BUILD_333${fix}_WINDOWS_RELEASE.zip',
        'STAVBY_PRO_RELEASE_MANAGER_8.0.0_DEV_BUILD_333_FIX375_WINDOWS_RELEASE.zip');
  });

  test('missing, invalid and ambiguous identity fail instead of falling back',
      () async {
    await expectLater(readWorkspaceExportFix(root.path), throwsStateError);
    for (final source in [
      "static const String stage = 'RC1 DEV015';\n",
      "static const String stage = 'RC1 DEV015 FIX375 FIX372';\n",
      "// static const String stage = 'RC1 DEV015 FIX372';\n",
      "static const String stage = 'RC1 DEV015 FIX375';\n"
          "static const String stage = 'RC1 DEV015 FIX372';\n",
    ]) {
      await identity.writeAsString(source);
      await expectLater(readWorkspaceExportFix(root.path), throwsStateError);
    }
  });
}
