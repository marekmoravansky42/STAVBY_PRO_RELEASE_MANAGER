import 'plugin_marketplace_cache.dart';
import 'plugin_marketplace_client.dart';
import 'plugin_marketplace_index.dart';
import 'plugin_marketplace_result.dart';
import 'plugin_marketplace_validator.dart';

/// Loads, validates and caches the catalogue with safe cache fallback.
class PluginMarketplaceRepository {
  PluginMarketplaceRepository({
    required PluginMarketplaceClient client,
    required PluginMarketplaceCache cache,
    PluginMarketplaceValidator validator = const PluginMarketplaceValidator(),
  })  : _client = client,
        _cache = cache,
        _validator = validator;

  final PluginMarketplaceClient _client;
  final PluginMarketplaceCache _cache;
  final PluginMarketplaceValidator _validator;

  Future<PluginMarketplaceResult<PluginMarketplaceIndex>> refresh(
    Uri indexUri,
  ) async {
    try {
      final index = await _client.fetchIndex(indexUri);
      final validation = _validator.validateIndex(index);
      if (!validation.isValid) {
        return PluginMarketplaceResult.failed(
          message: validation.errors.join('\n'),
        );
      }
      await _cache.write(index);
      return PluginMarketplaceResult.ok(
        index,
        message: 'Marketplace katalóg bol úspešne aktualizovaný.',
      );
    } catch (error, stackTrace) {
      try {
        final cached = await _cache.read();
        if (cached != null && _validator.validateIndex(cached).isValid) {
          return PluginMarketplaceResult.ok(
            cached,
            message: 'Použil sa lokálny marketplace katalóg.',
            fromCache: true,
          );
        }
      } catch (_) {
        // The original transport/parse failure is more useful to the caller.
      }
      return PluginMarketplaceResult.failed(
        message: 'Marketplace katalóg sa nepodarilo načítať.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<PluginMarketplaceResult<PluginMarketplaceIndex>> loadCache() async {
    try {
      final index = await _cache.read();
      if (index == null) {
        return PluginMarketplaceResult.failed(
          message: 'Lokálny marketplace katalóg neexistuje.',
        );
      }
      final validation = _validator.validateIndex(index);
      if (!validation.isValid) {
        return PluginMarketplaceResult.failed(
          message: validation.errors.join('\n'),
        );
      }
      return PluginMarketplaceResult.ok(index, fromCache: true);
    } catch (error, stackTrace) {
      return PluginMarketplaceResult.failed(
        message: 'Lokálny marketplace katalóg je poškodený.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
