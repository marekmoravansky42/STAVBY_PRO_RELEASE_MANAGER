/// Generic result returned by marketplace operations.
class PluginMarketplaceResult<T> {
  const PluginMarketplaceResult._({
    required this.success,
    required this.message,
    this.value,
    this.fromCache = false,
    this.error,
    this.stackTrace,
  });

  final bool success;
  final String message;
  final T? value;
  final bool fromCache;
  final Object? error;
  final StackTrace? stackTrace;

  factory PluginMarketplaceResult.ok(
    T value, {
    String message = 'Operácia bola úspešná.',
    bool fromCache = false,
  }) =>
      PluginMarketplaceResult<T>._(
        success: true,
        message: message,
        value: value,
        fromCache: fromCache,
      );

  factory PluginMarketplaceResult.failed({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      PluginMarketplaceResult<T>._(
        success: false,
        message: message,
        error: error,
        stackTrace: stackTrace,
      );
}
