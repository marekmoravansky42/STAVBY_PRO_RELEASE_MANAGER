import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/core/plugin_discovery/plugin_discovery.dart';

void main() {
  const parser = PluginManifestParser();

  test('parses a valid manifest and applies enabled default', () {
    final result = parser.parse('''
{
  "id": "stavby.exporter",
  "name": "STAVBY Exporter",
  "version": "1.2.0",
  "apiVersion": "1.0.0",
  "capabilities": ["artifact_exporter"]
}
''');

    expect(result.isValid, isTrue);
    expect(result.errors, isEmpty);
    expect(result.value!.enabled, isTrue);
    expect(result.value!.capabilities, <String>['artifact_exporter']);
  });

  test('serializes optional manifest fields', () {
    const manifest = PluginManifest(
      id: 'test.plugin',
      name: 'Test plugin',
      version: '1.0.0',
      apiVersion: '1.0.0',
      enabled: false,
      description: 'Testovací plugin',
      entryPoint: 'test_plugin',
    );

    final json = manifest.toJson();
    expect(json['enabled'], isFalse);
    expect(json['entryPoint'], 'test_plugin');
  });

  test('returns validation errors instead of throwing', () {
    final result = parser.parse('''
{
  "id": "Invalid ID",
  "name": "",
  "version": "1",
  "apiVersion": 1,
  "enabled": "yes"
}
''');

    expect(result.isValid, isFalse);
    expect(result.value, isNull);
    expect(result.errors, hasLength(5));
  });

  test('rejects malformed JSON', () {
    final result = parser.parse('{not-json}');

    expect(result.isValid, isFalse);
    expect(result.errors.single, contains('platný JSON'));
  });
}
