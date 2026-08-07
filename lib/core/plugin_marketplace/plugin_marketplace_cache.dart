import 'dart:convert';
import 'dart:io';

import 'plugin_marketplace_index.dart';

/// Atomic JSON cache for the marketplace catalogue.
class PluginMarketplaceCache {
  const PluginMarketplaceCache(this.cacheFile);

  final File cacheFile;

  Future<void> write(PluginMarketplaceIndex index) async {
    await cacheFile.parent.create(recursive: true);
    final temporary = File('${cacheFile.path}.tmp');
    await temporary.writeAsString(jsonEncode(index.toJson()), flush: true);
    if (await cacheFile.exists()) await cacheFile.delete();
    await temporary.rename(cacheFile.path);
  }

  Future<PluginMarketplaceIndex?> read() async {
    if (!await cacheFile.exists()) return null;
    final dynamic decoded = jsonDecode(await cacheFile.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Marketplace cache nemá platný JSON objekt.');
    }
    return PluginMarketplaceIndex.fromJson(decoded);
  }

  Future<void> clear() async {
    if (await cacheFile.exists()) await cacheFile.delete();
  }
}
