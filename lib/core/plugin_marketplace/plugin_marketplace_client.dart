import 'dart:convert';

import 'plugin_marketplace_index.dart';

/// Transport-neutral client. The host supplies the network/file loader.
typedef MarketplaceTextLoader = Future<String> Function(Uri uri);

class PluginMarketplaceClient {
  const PluginMarketplaceClient(this.loadText);

  final MarketplaceTextLoader loadText;

  Future<PluginMarketplaceIndex> fetchIndex(Uri indexUri) async {
    final source = await loadText(indexUri);
    final dynamic decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Marketplace index nemá platný JSON objekt.');
    }
    return PluginMarketplaceIndex.fromJson(decoded);
  }
}
