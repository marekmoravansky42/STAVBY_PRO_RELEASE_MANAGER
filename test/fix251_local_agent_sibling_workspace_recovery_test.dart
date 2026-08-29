import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/core/remote_agents/local_agent_controller.dart';

void main() {
  test('FIX251 finds Local Agent in sibling Release Manager workspace', () async {
    final temp = await Directory.systemTemp.createTemp('fix251_agent_');
    addTearDown(() => temp.delete(recursive: true));

    final appWorkspace = Directory('${temp.path}${Platform.pathSeparator}STAVBY_PRO')
      ..createSync(recursive: true);
    final agentDir = Directory(
      '${temp.path}${Platform.pathSeparator}Release_Manager'
      '${Platform.pathSeparator}tools${Platform.pathSeparator}release_agent',
    )..createSync(recursive: true);
    File('${agentDir.path}${Platform.pathSeparator}pubspec.yaml')
        .writeAsStringSync('name: test_agent\n');

    final controller = LocalAgentController();
    final found = await controller.findAgentDirectory(
      projectRoot: appWorkspace.path,
    );

    expect(found.absolute.path, agentDir.absolute.path);
  });
}
