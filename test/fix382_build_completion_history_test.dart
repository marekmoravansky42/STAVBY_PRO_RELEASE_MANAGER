import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stavby_pro_release_manager/services/build_completion_history_service.dart';

Map<String, Object?> record({
  String version = '8.0.0',
  int build = 333,
  String result = 'Hotovo',
}) =>
    <String, Object?>{
      'project': 'Release_Manager',
      'workspace': r'C:\SP\Release_Manager',
      'version': version,
      'build': build,
      'stage': 'rc1',
      'releaseType': 'RC',
      'branch': 'dev',
      'commitMessage': 'Release Manager $version RC - Build $build',
      'tagName': '',
      'options': <String, bool>{'history': true, 'commit': false},
      'results': <Map<String, Object?>>[
        <String, Object?>{
          'name': 'Git commit',
          'success': true,
          'message': result
        },
      ],
      'completedAt': DateTime.now().toIso8601String(),
      'releaseZip': 'an intentionally ignored path',
    };

void main() {
  test(
      'identical completion is saved once; changed result or identity is appended',
      () async {
    final root = await Directory.systemTemp.createTemp('fix382_history_');
    addTearDown(() => root.delete(recursive: true));
    final file = File(path.join(root.path, 'build_completion_history.json'));

    expect(await appendBuildCompletionHistory(file, record()),
        BuildCompletionHistoryWrite.appended);
    expect(await appendBuildCompletionHistory(file, record()),
        BuildCompletionHistoryWrite.duplicate);
    var history = jsonDecode(await file.readAsString()) as List;
    expect(history, hasLength(1));

    expect(
        await appendBuildCompletionHistory(file, record(result: 'Preskočené')),
        BuildCompletionHistoryWrite.appended);
    expect(await appendBuildCompletionHistory(file, record(build: 334)),
        BuildCompletionHistoryWrite.appended);
    history = jsonDecode(await file.readAsString()) as List;
    expect(history, hasLength(3));
  });
}
