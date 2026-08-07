import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/core/plugin_marketplace/plugin_marketplace.dart';

PluginMarketplaceManifest manifest({
  String id = 'sample.plugin',
  String name = 'Sample Plugin',
  String author = 'STAVBY PRO',
  String category = 'release',
}) =>
    PluginMarketplaceManifest(
      id: id,
      name: name,
      author: author,
      version: '1.0.0',
      apiVersion: '1',
      minimumReleaseManagerVersion: '6.4.1',
      downloadUrl: 'https://example.invalid/$id.zip',
      sha256: List<String>.filled(64, 'a').join(),
      description: 'Release automation plugin',
      categories: <String>[category],
    );

void main() {
  test('index survives JSON round-trip', () {
    final index = PluginMarketplaceIndex(
      schemaVersion: 1,
      generatedAt: DateTime.utc(2026, 7, 31),
      plugins: <PluginMarketplaceManifest>[manifest()],
    );
    final decoded = PluginMarketplaceIndex.fromJson(
      jsonDecode(jsonEncode(index.toJson())) as Map<String, dynamic>,
    );
    expect(decoded.plugins.single.id, 'sample.plugin');
    expect(decoded.generatedAt, DateTime.utc(2026, 7, 31));
  });

  test('search filters and sorts catalogue', () {
    final index = PluginMarketplaceIndex(
      schemaVersion: 1,
      generatedAt: DateTime.now().toUtc(),
      plugins: <PluginMarketplaceManifest>[
        manifest(id: 'z.plugin', name: 'Zulu'),
        manifest(id: 'a.plugin', name: 'Alpha'),
        manifest(id: 'other.plugin', name: 'Other', category: 'diagnostics'),
      ],
    );
    final results = const PluginMarketplaceSearch().search(
      index,
      category: 'release',
    );
    expect(results.map((item) => item.name), <String>['Alpha', 'Zulu']);
  });

  test('validator rejects duplicate IDs', () {
    final index = PluginMarketplaceIndex(
      schemaVersion: 1,
      generatedAt: DateTime.now().toUtc(),
      plugins: <PluginMarketplaceManifest>[manifest(), manifest()],
    );
    final result = const PluginMarketplaceValidator().validateIndex(index);
    expect(result.isValid, isFalse);
    expect(result.errors.any((value) => value.contains('Duplicitné')), isTrue);
  });

  test('package checksum is verified', () async {
    final directory = await Directory.systemTemp.createTemp('rm_marketplace_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}plugin.zip');
    final bytes = utf8.encode('safe plugin package');
    await file.writeAsBytes(bytes);
    final expected = sha256.convert(bytes).toString();
    final valid = await const PluginMarketplaceValidator()
        .verifyPackage(file, expected);
    expect(valid, isTrue);
  });

  test('repository falls back to valid cache', () async {
    final directory = await Directory.systemTemp.createTemp('rm_marketplace_');
    addTearDown(() => directory.delete(recursive: true));
    final cache = PluginMarketplaceCache(File('${directory.path}/index.json'));
    final index = PluginMarketplaceIndex(
      schemaVersion: 1,
      generatedAt: DateTime.now().toUtc(),
      plugins: <PluginMarketplaceManifest>[manifest()],
    );
    await cache.write(index);
    final repository = PluginMarketplaceRepository(
      client: PluginMarketplaceClient((_) async => throw StateError('offline')),
      cache: cache,
    );
    final result = await repository.refresh(Uri.parse('https://example.invalid/index.json'));
    expect(result.success, isTrue);
    expect(result.fromCache, isTrue);
    expect(result.value?.plugins.single.id, 'sample.plugin');
  });
}
