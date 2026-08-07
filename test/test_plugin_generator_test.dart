import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/core/plugin_test_generator/plugin_test_generator.dart';

void main() {
  test('generates an installable test plugin package', () async {
    final root = await Directory.systemTemp.createTemp('rm_test_plugin_');
    addTearDown(() => root.delete(recursive: true));

    const generator = TestPluginGenerator();
    final result = await generator.generate(
      TestPluginGenerationRequest(
        parentDirectory: root,
        pluginId: 'stavby.test-plugin',
        pluginName: 'STAVBY Test Plugin',
      ),
    );

    expect(result.success, isTrue);
    final directory = result.pluginDirectory!;
    expect(File('${directory.path}${Platform.pathSeparator}plugin.json').existsSync(), isTrue);
    expect(File('${directory.path}${Platform.pathSeparator}lib${Platform.pathSeparator}plugin.dart').existsSync(), isTrue);
  });
}
