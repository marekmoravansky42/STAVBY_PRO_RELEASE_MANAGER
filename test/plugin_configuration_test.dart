import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/core/plugin_configuration/plugin_configuration.dart';

void main() {
  late Directory temporaryDirectory;
  late PluginConfigurationManager manager;

  final schema = PluginConfigurationSchema(
    pluginId: 'test.plugin',
    version: 2,
    fields: <PluginConfigurationField>[
      PluginConfigurationField(
        key: 'enabled',
        type: PluginConfigurationValueType.boolean,
        defaultValue: true,
      ),
      PluginConfigurationField(
        key: 'endpoint',
        type: PluginConfigurationValueType.string,
        required: true,
      ),
    ],
  );

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp('rm_plugin_config_');
    manager = PluginConfigurationManager(
      storage: PluginConfigurationStorage(rootDirectory: temporaryDirectory),
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('validates and persists configuration', () async {
    final saved = await manager.save(
      schema: schema,
      values: const <String, dynamic>{
        'endpoint': 'https://example.test',
        'unknown': 1,
      },
    );

    expect(saved.isValid, isTrue);
    expect(saved.configuration['enabled'], isTrue);
    expect(saved.configuration.containsKey('unknown'), isFalse);

    final loaded = await manager.load(schema: schema);
    expect(loaded.isValid, isTrue);
    expect(loaded.configuration['endpoint'], 'https://example.test');
  });

  test('reports invalid values without writing them', () async {
    final result = await manager.save(
      schema: schema,
      values: const <String, dynamic>{
        'enabled': 'yes',
      },
    );

    expect(result.isValid, isFalse);
    expect(result.errors, isNotEmpty);
  });

  test('migrates an older configuration schema', () async {
    final storage = PluginConfigurationStorage(rootDirectory: temporaryDirectory);
    await storage.save(
      pluginId: schema.pluginId,
      schemaVersion: 1,
      values: const <String, dynamic>{'url': 'https://old.test'},
    );

    final result = await manager.load(
      schema: schema,
      migrate: (fromVersion, values) => <String, dynamic>{
        'endpoint': values['url'],
      },
    );

    expect(result.isValid, isTrue);
    expect(result.configuration['endpoint'], 'https://old.test');
  });
}
